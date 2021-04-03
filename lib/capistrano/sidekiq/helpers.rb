module Capistrano
  module Sidekiq::Helpers
    def sidekiq_require
      if fetch(:sidekiq_require)
        "--require #{fetch(:sidekiq_require)}"
      end
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

    def sidekiq_queues
      Array(fetch(:sidekiq_queue)).map do |queue|
        "--queue #{queue}"
      end.join(' ')
    end

    def sidekiq_logfile
      fetch(:sidekiq_log)
    end

    def switch_user(role)
      su_user = sidekiq_user(role)
      if su_user == role.user
        yield
      else
        as su_user do
          yield
        end
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
  end
end
