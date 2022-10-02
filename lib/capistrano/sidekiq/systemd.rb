# frozen_string_literal: true

module Capistrano
  class Sidekiq::Systemd < Capistrano::Plugin
    include Sidekiq::Helpers

    def set_defaults
      set_if_empty :sidekiq_systemctl_bin, -> { fetch(:systemctl_bin, '/bin/systemctl') }
      set_if_empty :sidekiq_service_unit_name, -> { "#{fetch(:application)}_sidekiq_#{fetch(:stage)}" }
      set_if_empty :sidekiq_service_unit_user, -> { fetch(:service_unit_user, :user) }
      set_if_empty :sidekiq_enable_lingering, -> { fetch(:puma_systemctl_user) != :system }
      set_if_empty :sidekiq_lingering_user, -> { fetch(:lingering_user, fetch(:user)) }

      set_if_empty :sidekiq_service_unit_env_files, -> { fetch(:service_unit_env_files, []) }
      set_if_empty :sidekiq_service_unit_env_vars, -> { fetch(:service_unit_env_vars, []) }

      set_if_empty :sidekiq_service_templates_path, fetch(:service_templates_path, 'config/deploy/templates')
    end

    def define_tasks
      eval_rakefile File.expand_path('../tasks/systemd.rake', __dir__)
    end
  end
end
