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
        start_time = Time.now
        running = nil

        # get running workers
        while (running.nil? || running > 0) && start_time > 30.seconds.ago do
          command_args =
            if fetch(:sidekiq_service_unit_user) == :system
              [:sudo, :systemctl]
            else
              [:systemctl, "--user"]
            end
          command_args.push(:status, git_plugin.sidekiq_service_unit_name)
          status = capture(*command_args, raise_on_non_zero_exit: false)
          status_match = status.match(/\[(?<running>\d+) of (?<total>\d+) busy\]/)
          next unless status_match

          running = status_match[:running]&.to_i

          colors = SSHKit::Color.new($stdout)
          if running.zero?
            puts colors.colorize('    ✔ No running workers. Shutting down for restart!', :green)
          else
            puts colors.colorize("    ⧗ Waiting for #{running} workers.", :yellow)
          end
        end

        git_plugin.systemctl_command(:stop)
        git_plugin.systemctl_command(:start)
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
        git_plugin.systemctl_command(:enable)

        if fetch(:sidekiq_service_unit_user) != :system && fetch(:sidekiq_enable_lingering)
          execute :loginctl, "enable-linger", fetch(:sidekiq_lingering_user)
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
      "/etc/systemd/system/"
    else
      home_dir = backend.capture :pwd
      File.join(home_dir, ".config", "systemd", "user")
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
      ),
    ]
    template_path = search_paths.detect { |path| File.file?(path) }
    template = File.read(template_path)
    ERB.new(template).result(binding)
  end

  def create_systemd_template
    ctemplate = compiled_template
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    systemd_file_name = File.join(systemd_path, sidekiq_service_file_name)

    if fetch(:sidekiq_service_unit_user) == :user
      backend.execute :mkdir, "-p", systemd_path
    end

    temp_file_name = File.join('/tmp', sidekiq_service_file_name)
    backend.upload!(StringIO.new(ctemplate), temp_file_name)
    if fetch(:sidekiq_service_unit_user) == :system
      backend.execute :sudo, :mv, temp_file_name, systemd_file_name
      backend.execute :sudo, :systemctl, "daemon-reload"
    else
      backend.execute :mv, temp_file_name, systemd_file_name
      backend.execute :systemctl, "--user", "daemon-reload"
    end
  end

  def systemctl_command(*args)
    execute_array =
      if fetch(:sidekiq_service_unit_user) == :system
        [:sudo, :systemctl]
      else
        [:systemctl, '--user']
      end
    execute_array.push(*args, sidekiq_service_unit_name).flatten
    backend.execute(*execute_array, raise_on_non_zero_exit: false)
  end

  def quiet_sidekiq
    systemctl_command(:kill, '-s', :TSTP)
  end

  def switch_user(role)
    su_user = sidekiq_user
    if su_user != role.user
      yield
    else
      backend.as su_user do
        yield
      end
    end
  end

  def sidekiq_user
    fetch(:sidekiq_user, fetch(:run_as))
  end

  def sidekiq_config
    if fetch(:sidekiq_config)
      "--config #{fetch(:sidekiq_config)}"
    end
  end

  def sidekiq_concurrency
    if fetch(:sidekiq_concurrency)
      "--concurrency #{fetch(:sidekiq_concurrency)}"
    end
  end

  def sidekiq_processes
    fetch(:sidekiq_processes, 1)
  end

  def sidekiq_queues
    Array(fetch(:sidekiq_queue)).map do |queue|
      "--queue #{queue}"
    end.join(' ')
  end

  def sidekiq_service_file_name
    "#{fetch :sidekiq_service_unit_name}@.service"
  end

  def sidekiq_service_unit_name
    "#{fetch(:sidekiq_service_unit_name)}@{1..#{sidekiq_processes}}"
  end

end
