module Capistrano
  class Sidekiq::Systemd < Capistrano::Plugin
    def set_defaults
      set_if_empty :sidekiq_service_unit_name, 'sidekiq'
      set_if_empty :sidekiq_service_unit_user, :user # :system
    end

    def define_tasks
      eval_rakefile File.expand_path('../../tasks/systemd.rake', __FILE__)
    end
  end
end
