# frozen_string_literal: true

git_plugin = self

namespace :sidekiq do
  standard_actions = {
    start: 'Start Sidekiq',
    stop: 'Stop Sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)',
    status: 'Get Sidekiq Status',
  }
  standard_actions.each do |command, description|
    desc description
    task command do
      on roles fetch(:sidekiq_roles) do |role|
        git_plugin.switch_user(role) do
          git_plugin.config_files(role).each do |config_file|
            git_plugin.execute_systemd(command, git_plugin.sidekiq_service_file_name(config_file))
          end
        end
      end
    end
  end

  desc "Custom Restart Sidekiq (Quiet active service and start inactive service)"
  task :restart do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        colors = SSHKit::Color.new($stdout)
        processes = git_plugin.config_files(role).each_with_object([]) do |config_file, result|
          info colors.colorize("config_files: #{config_file}", :green)
          active_process = nil
          inactive_process = nil
          [1, 2].each do |process|
            sidekiq_service_unit_name = git_plugin.sidekiq_service_unit_name(config_file, process: process)
            command_args =
              if fetch(:sidekiq_service_unit_user) == :system
                [:sudo, "systemctl"]
              else
                ["systemctl", "--user"]
              end
  
            command_args.push(:status, sidekiq_service_unit_name)
            status = capture(*command_args, raise_on_non_zero_exit: false)

            active_status_match = status.match(/Active: active/)
            inactive_status_match = status.match(/Active: inactive/)
  
            if active_status_match
              active_process = sidekiq_service_unit_name
            elsif inactive_status_match
              inactive_process = sidekiq_service_unit_name
            else
              info colors.colorize("Process ##{process} status not match: #{status}", :red)
            end
          end

          sidekiq_service_unit_name = git_plugin.sidekiq_service_unit_name(config_file)
          if active_process.nil?
            info colors.colorize("Can not find active process of #{sidekiq_service_unit_name}", :yellow)
          end
          if inactive_process.nil?
            info colors.colorize(
              "Can not find inactive process of #{sidekiq_service_unit_name}, You should manually restart sidekiq", :red
            )
            return
          end
          result << [active_process, inactive_process]
        end
      
        processes.each do |(active_process, inactive_process)|
          info colors.colorize("Quiet Process ##{active_process || "-"}, Start Process ##{inactive_process}", :green)
          git_plugin.execute_systemd("kill -s TSTP", active_process) unless active_process.nil?
          git_plugin.execute_systemd("start", inactive_process)
        end
      end
    end
  end

  desc 'Quiet Sidekiq (stop fetching new tasks from Redis)'
  task :quiet do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.quiet_sidekiq(role)
      end
    end
  end

  desc 'Install Sidekiq systemd service'
  task :install do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.create_systemd_template(role)
      end
    end
    invoke 'sidekiq:enable'
  end

  desc 'Uninstall Sidekiq systemd service'
  task :uninstall do
    invoke 'sidekiq:disable'
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.rm_systemd_service(role)
      end
    end
  end

  desc 'Enable Sidekiq systemd service'
  task :enable do
    on roles(fetch(:sidekiq_roles)) do |role|
      git_plugin.config_files(role).each do |config_file|
        git_plugin.execute_systemd("enable", git_plugin.sidekiq_service_file_name(config_file))
      end

      if fetch(:systemctl_user) && fetch(:sidekiq_lingering_user)
        execute :loginctl, "enable-linger", fetch(:puma_lingering_user)
      end
    end
  end

  desc 'Disable Sidekiq systemd service'
  task :disable do
    on roles(fetch(:sidekiq_roles)) do |role|
      git_plugin.config_files(role).each do |config_file|
        git_plugin.execute_systemd("disable", git_plugin.sidekiq_service_file_name(config_file))
      end
    end
  end

  def fetch_systemd_unit_path
    if fetch(:puma_systemctl_user) == :system
      "/etc/systemd/system/"
    else
      home_dir = backend.capture :pwd
      File.join(home_dir, ".config", "systemd", "user")
    end
  end

  def create_systemd_template(role)
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    backend.execute :mkdir, '-p', systemd_path if fetch(:systemctl_user)

    config_files(role).each do |config_file|
        ctemplate = compiled_template(config_file)
        temp_file_name = File.join('/tmp', "sidekiq.#{config_file}.service")
        systemd_file_name = File.join(systemd_path, sidekiq_service_file_name(config_file))
        backend.upload!(StringIO.new(ctemplate), temp_file_name)
        if fetch(:systemctl_user)
          warn "Moving #{temp_file_name} to #{systemd_file_name}"
          backend.execute :mv, temp_file_name, systemd_file_name
        else
          warn "Installing #{systemd_file_name} as root"
          backend.execute :sudo, :mv, temp_file_name, systemd_file_name
        end
    end
  end

  def rm_systemd_service(role)
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)

    config_files(role).each do |config_file|
      systemd_file_name = File.join(systemd_path, sidekiq_service_file_name(config_file))
      if fetch(:systemctl_user)
        warn "Deleting #{systemd_file_name}"
        backend.execute :rm, "-f", systemd_file_name
      else
        warn "Deleting #{systemd_file_name} as root"
        backend.execute :sudo, :rm, "-f", systemd_file_name
      end
    end
  end

  def quiet_sidekiq(role)
    config_files(role).each do |config_file|
      sidekiq_service = sidekiq_service_unit_name(config_file)
      warn "Quieting #{sidekiq_service}"
      execute_systemd("kill -s TSTP", sidekiq_service)
    end
  end

  def sidekiq_service_unit_name(config_file, process: nil)
    service_unit_name =
      if config_file != "sidekiq.yml"
        fetch(:sidekiq_service_unit_name) + "." + config_file.split(".")[0..-2].join(".")
      else
        fetch(:sidekiq_service_unit_name)
      end
    if process != nil && process > 1
      "#{service_unit_name}_#{process}"
    else
      service_unit_name
    end
  end

  def sidekiq_service_file_name(config_file)
    ## Remove the extension
    config_file = config_file.split('.')[0..-1].join('.')

    "#{sidekiq_service_unit_name(config_file)}.service"
  end

  def config_files(role)
    role.properties.fetch(:sidekiq_config_files) ||
      fetch(:sidekiq_config_files)
  end
end
