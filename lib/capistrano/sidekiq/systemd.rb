# frozen_string_literal: true

module Capistrano
  class Sidekiq::Systemd < Capistrano::Plugin
    include SidekiqCommon
    def define_tasks
      eval_rakefile File.expand_path('../tasks/systemd.rake', __dir__)
    end
    def set_defaults
      set_if_empty :systemctl_bin, '/bin/systemctl'
      set_if_empty :service_unit_user, :user
      set_if_empty :systemctl_user, fetch(:service_unit_user, :user) == :user

      set_if_empty :sidekiq_systemctl_user, -> { fetch(:service_unit_user) }
      set_if_empty :sidekiq_service_unit_name, -> { "#{fetch(:application)}_sidekiq_#{fetch(:stage)}" }
      set_if_empty :sidekiq_lingering_user, -> { fetch(:lingering_user, fetch(:user)) }

      ## Sidekiq could have a stripped down or more complex version of the environment variables
      set_if_empty :sidekiq_service_unit_env_files, -> { fetch(:service_unit_env_files, []) }
      set_if_empty :sidekiq_service_unit_env_vars, -> { fetch(:service_unit_env_vars, []) }

      set_if_empty :sidekiq_service_templates_path, fetch(:service_templates_path, 'config/deploy/templates')
    end

    def systemd_command(*args)
      command = [fetch(:systemctl_bin)]

      unless fetch(:sidekiq_systemctl_user) == :system
        command << "--user"
      end

      command + args
    end

    def sudo_if_needed(*command)
      if fetch(:sidekiq_systemctl_user) == :system
        backend.sudo command.map(&:to_s).join(" ")
      else
        backend.execute(*command)
      end
    end

    def execute_systemd(*args)
      sudo_if_needed(*systemd_command(*args))
    end
  end
end
