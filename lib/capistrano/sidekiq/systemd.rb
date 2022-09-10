# frozen_string_literal: true

module Capistrano
  class Sidekiq::Systemd < Capistrano::Plugin
    include Sidekiq::Helpers

    def set_defaults
      set_if_empty :sidekiq_systemctl_bin, '/bin/systemctl'
      set_if_empty :sidekiq_service_unit_name, -> { "sidekiq_#{fetch(:application)}_#{fetch(:stage)}" }
      set_if_empty :sidekiq_service_unit_user, :user # :system
      set_if_empty :sidekiq_enable_lingering, true
      set_if_empty :sidekiq_lingering_user, nil
      set_if_empty :sidekiq_service_templates_path, 'config/deploy/templates'
    end

    def define_tasks
      eval_rakefile File.expand_path('../tasks/systemd.rake', __dir__)
    end
  end
end
