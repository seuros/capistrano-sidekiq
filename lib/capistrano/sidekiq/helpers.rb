# frozen_string_literal: true

module Capistrano
  module Sidekiq::Helpers

    def sidekiq_require
      "--require #{fetch(:sidekiq_require)}" if fetch(:sidekiq_require)
    end

    def sidekiq_config
      "--config #{fetch(:sidekiq_config)}" if fetch(:sidekiq_config)
    end

    def sidekiq_concurrency
      "--concurrency #{fetch(:sidekiq_concurrency)}" if fetch(:sidekiq_concurrency)
    end

    def sidekiq_queues
      Array(fetch(:sidekiq_queue)).map do |queue|
        "--queue #{queue}"
      end.join(' ')
    end

    def sidekiq_logfile
      fetch(:sidekiq_log)
    end

    def switch_user(role, &block)
      su_user = sidekiq_user(role)
      if su_user == role.user
        yield
      else
        as su_user, &block
      end
    end

    def sidekiq_user(role = nil)
      if role.nil?
        fetch(:sidekiq_user)
      else
        properties = role.properties
        properties.fetch(:sidekiq_user) || # local property for sidekiq only
          fetch(:sidekiq_user) ||
          properties.fetch(:run_as) || # global property across multiple capistrano gems
          role.user
      end
    end

    def expanded_bundle_path
      backend.capture(:echo, SSHKit.config.command_map[:bundle]).strip
    end
  end
end
