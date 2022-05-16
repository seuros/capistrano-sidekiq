# frozen_string_literal: true

module Capistrano
  class Sidekiq::Upstart < Capistrano::Plugin
    include Sidekiq::Helpers

    def set_defaults
      set_if_empty :sidekiq_service_unit_name, 'sidekiq' # This will change in version 3.0.0 to {application}-sidekiq
    end

    def define_tasks
      eval_rakefile File.expand_path('../tasks/upstart.rake', __dir__)
    end
  end
end
