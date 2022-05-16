# frozen_string_literal: true

git_plugin = self

namespace :sidekiq do
  standard_actions = {
    start: 'Start Sidekiq',
    stop: 'Stop Sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)',
    status: 'Get Sidekiq Status'
  }
  standard_actions.each do |command, description|
    desc description
    task command do
      on roles fetch(:sidekiq_roles) do |role|
        git_plugin.switch_user(role) do
          git_plugin.systemctl_command(command)
        end
      end
    end
  end

  desc 'Restart Sidekiq (Quiet, Wait till workers finish or 30 seconds, Stop, Start)'
  task :restart do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.quiet_sidekiq
        git_plugin.process_block do |process|
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          running = nil

          # get running workers
          while (running.nil? || running > 0) && git_plugin.duration(start_time) < 30 do
            command_args =
              if fetch(:sidekiq_service_unit_user) == :system
                [:sudo, 'systemd-cgls']
              else
                ['systemd-cgls', '--user']
              end
            # need to pipe through tr -cd... to strip out systemd colors or you
            # get log error messages for non UTF-8 characters.
            command_args.push(
              '-u', "#{git_plugin.sidekiq_service_unit_name(process: process)}.service",
              '|', 'tr -cd \'\11\12\15\40-\176\''
            )
            status = capture(*command_args, raise_on_non_zero_exit: false)
            status_match = status.match(/\[(?<running>\d+) of (?<total>\d+) busy\]/)
            break unless status_match

            running = status_match[:running]&.to_i

            colors = SSHKit::Color.new($stdout)
            if running.zero?
              info colors.colorize("✔ Process ##{process}: No running workers. Shutting down for restart!", :green)
            else
              info colors.colorize("⧗ Process ##{process}: Waiting for #{running} workers.", :yellow)
              sleep(1)
            end
          end

          git_plugin.systemctl_command(:stop, process: process)
          git_plugin.systemctl_command(:start, process: process)
        end
      end
    end
  end

  desc 'Quiet Sidekiq (stop fetching new tasks from Redis)'
  task :quiet do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.quiet_sidekiq
      end
    end
  end

  desc 'Install systemd sidekiq service'
  task :install do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.create_systemd_template
        if git_plugin.config_per_process?
          git_plugin.process_block do |process|
            git_plugin.create_systemd_config_symlink(process)
          end
        end
        git_plugin.systemctl_command(:enable)

        if fetch(:sidekiq_service_unit_user) != :system && fetch(:sidekiq_enable_lingering)
          execute :loginctl, 'enable-linger', fetch(:sidekiq_lingering_user)
        end
      end
    end
  end

  desc 'Uninstall systemd sidekiq service'
  task :uninstall do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.systemctl_command(:stop)
        git_plugin.systemctl_command(:disable)
        if git_plugin.config_per_process?
          git_plugin.process_block do |process|
            git_plugin.delete_systemd_config_symlink(process)
          end
        end
        execute :sudo, :rm, '-f', File.join(
          fetch(:service_unit_path, git_plugin.fetch_systemd_unit_path),
          git_plugin.sidekiq_service_file_name
        )
      end
    end
  end

  desc 'Generate service_locally'
  task :generate_service_locally do
    run_locally do
      File.write('sidekiq', git_plugin.compiled_template)
    end
  end

  def fetch_systemd_unit_path
    if fetch(:sidekiq_service_unit_user) == :system
      # if the path is not standard `set :service_unit_path`
      '/etc/systemd/system/'
    else
      home_dir = backend.capture :pwd
      File.join(home_dir, '.config', 'systemd', 'user')
    end
  end

  def compiled_template
    local_template_directory = fetch(:sidekiq_service_templates_path)
    search_paths = [
      File.join(local_template_directory, "#{fetch(:sidekiq_service_unit_name)}.service.capistrano.erb"),
      File.join(local_template_directory, 'sidekiq.service.capistrano.erb'),
      File.expand_path(
        File.join(*%w[.. .. .. generators capistrano sidekiq systemd templates sidekiq.service.capistrano.erb]),
        __FILE__
      )
    ]
    template_path = search_paths.detect { |path| File.file?(path) }
    template = File.read(template_path)
    ERB.new(template).result(binding)
  end

  def create_systemd_template
    ctemplate = compiled_template
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    backend.execute :mkdir, '-p', systemd_path if fetch(:sidekiq_service_unit_user) == :user

    if sidekiq_processes > 1
      range = 1..sidekiq_processes
    else
      range = 0..0
    end
    range.each do |index|
      temp_file_name = File.join('/tmp', sidekiq_service_file_name(index))
      systemd_file_name = File.join(systemd_path, sidekiq_service_file_name(index))
      backend.upload!(StringIO.new(ctemplate), temp_file_name)

      if fetch(:sidekiq_service_unit_user) == :system
        backend.execute :sudo, :mv, temp_file_name, systemd_file_name
        backend.execute :sudo, :systemctl, 'daemon-reload'
      else
        backend.execute :mv, temp_file_name, systemd_file_name
        backend.execute :systemctl, '--user', 'daemon-reload'
      end
    end
  end

  def create_systemd_config_symlink(process)
    config = fetch(:sidekiq_config)
    return unless config

    process_config = config[process - 1]
    if process_config.nil?
      backend.error(
        "No configuration for Process ##{process} found. "\
        'Please make sure you have 1 item in :sidekiq_config for each process.'
      )
      exit 1
    end

    base_path = fetch(:deploy_to)
    config_link_base_path = File.join(base_path, 'shared', 'sidekiq_systemd')
    config_link_path = File.join(
      config_link_base_path, sidekiq_systemd_config_name(process)
    )
    process_config_path = File.join(base_path, 'current', process_config)

    backend.execute :mkdir, '-p', config_link_base_path
    backend.execute :ln, '-sf', process_config_path, config_link_path
  end

  def delete_systemd_config_symlink(process)
    config_link_path = File.join(
      fetch(:deploy_to), 'shared', 'sidekiq_systemd',
      sidekiq_systemd_config_name(process)
    )
    backend.execute :rm, config_link_path, raise_on_non_zero_exit: false
  end

  def systemctl_command(*args, process: nil)
    execute_array =
      if fetch(:sidekiq_service_unit_user) == :system
        %i[sudo systemctl]
      else
        [:systemctl, '--user']
      end
    if process && sidekiq_processes > 1
      execute_array.push(
        *args, sidekiq_service_unit_name(process: process)
        ).flatten
    else
      execute_array.push(*args, sidekiq_service_unit_name).flatten
    end
    backend.execute(*execute_array, raise_on_non_zero_exit: false)
  end

  def quiet_sidekiq
    systemctl_command(:kill, '-s', :TSTP)
  end

  def switch_user(role, &block)
    su_user = sidekiq_user
    if su_user != role.user
      yield
    else
      backend.as su_user, &block
    end
  end

  def sidekiq_user
    fetch(:sidekiq_user, fetch(:run_as))
  end

  def sidekiq_config
    config = fetch(:sidekiq_config)
    return unless config

    if config_per_process?
      config = File.join(
        fetch(:deploy_to), 'shared', 'sidekiq_systemd',
        sidekiq_systemd_config_name
      )
    end
    "--config #{config}"
  end

  def sidekiq_concurrency
    "--concurrency #{fetch(:sidekiq_concurrency)}" if fetch(:sidekiq_concurrency)
  end

  def sidekiq_processes
    fetch(:sidekiq_processes, 1)
  end

  def sidekiq_queues
    Array(fetch(:sidekiq_queue)).map do |queue|
      "--queue #{queue}"
    end.join(' ')
  end

  def sidekiq_service_file_name(index = nil)
    return "#{fetch(:sidekiq_service_unit_name)}.service" if index.to_i.zero?
    "#{fetch(:sidekiq_service_unit_name)}@#{index}.service"
  end

  def sidekiq_service_unit_name(process: nil)
    if process && sidekiq_processes > 1
      "#{fetch(:sidekiq_service_unit_name)}@#{process}"
    else
      fetch(:sidekiq_service_unit_name)
    end
  end

  # process = 1 | sidekiq_systemd_1.yaml
  # process = nil | sidekiq_systemd_%i.yaml
  def sidekiq_systemd_config_name(process = nil)
   "sidekiq_systemd_#{(process&.to_s || '%i')}.yaml"
  end

  def config_per_process?
    fetch(:sidekiq_config).is_a?(Array)
  end

  def process_block
    (1..sidekiq_processes).each do |process|
      yield(process)
    end
  end

  def duration(start_time)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
  end
end
