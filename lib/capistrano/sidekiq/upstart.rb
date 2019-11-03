module Capistrano
  class Sidekiq::Upstart < Capistrano::Plugin
    def set_defaults
      set_if_empty :sidekiq_service_unit_name, 'sidekiq'
    end

    def define_tasks
      eval_rakefile File.expand_path('../../tasks/upstart.rake', __FILE__)
    end
  end
end
