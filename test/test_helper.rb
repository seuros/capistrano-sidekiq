# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'

# Set up a minimal Capistrano environment for testing
module Capistrano
  class Plugin
    def set_defaults; end
    def define_tasks; end
    def register_hooks; end
  end

  module DSL
    module Env
      def fetch(key, default = nil, &block)
        @config ||= {}
        @config[key] || (block_given? ? block.call : default)
      end

      def set(key, value)
        @config ||= {}
        @config[key] = value
      end

      def set_if_empty(key, value)
        @config ||= {}
        @config[key] ||= value.respond_to?(:call) ? value : value
      end

      def append(key, *values)
        @config ||= {}
        @config[key] ||= []
        @config[key].concat(values)
      end
    end
  end

  class Configuration
    include DSL::Env
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  class Plugin
    include DSL::Env

    def self.config
      Capistrano.configuration
    end

    def fetch(*, &)
      self.class.config.fetch(*, &)
    end

    def set(*)
      self.class.config.set(*)
    end

    def set_if_empty(*)
      self.class.config.set_if_empty(*)
    end

    def append(*)
      self.class.config.append(*)
    end
  end
end

# Load the gem
require 'capistrano/sidekiq'
