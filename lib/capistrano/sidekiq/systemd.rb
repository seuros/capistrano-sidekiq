module Capistrano
  class Sidekiq::Systemd < Capistrano::Plugin
    include Sidekiq::Helpers

    def set_defaults
      set_if_empty :sidekiq_service_unit_name, 'sidekiq'
      set_if_empty :sidekiq_service_unit_user, :user # :system
      set_if_empty :sidekiq_enable_lingering, true
      set_if_empty :sidekiq_lingering_user, nil
    end

    def define_tasks
      eval_rakefile File.expand_path('../../tasks/systemd.rake', __FILE__)
    end
  end
end
