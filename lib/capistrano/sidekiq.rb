# frozen_string_literal: true

require 'capistrano/bundler'
require 'capistrano/plugin'

module Capistrano
  module SidekiqCommon
    def compiled_template(config_file = "sidekiq.yml")
      @config_file = config_file
      local_template_directory = fetch(:sidekiq_service_templates_path)
      search_paths = [
        File.join(local_template_directory, 'sidekiq.service.capistrano.erb'),
        File.expand_path(
          File.join(*%w[.. templates sidekiq.service.capistrano.erb]),
          __FILE__
        )
      ]
      template_path = search_paths.detect { |path| File.file?(path) }
      template = File.read(template_path)
      ERB.new(template, trim_mode: '-').result(binding)
    end

    def expanded_bundle_path
      backend.capture(:echo, SSHKit.config.command_map[:bundle]).strip
    end

    def sidekiq_config
      "--config config/#{@config_file}" if @config_file != "sidekiq.yml"
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
  end
  class Sidekiq < Capistrano::Plugin
    def define_tasks
      eval_rakefile File.expand_path('tasks/sidekiq.rake', __dir__)
    end

    def set_defaults
      set_if_empty :sidekiq_default_hooks, true

      set_if_empty :sidekiq_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:rake_env, fetch(:stage)))) }
      set_if_empty :sidekiq_roles, fetch(:sidekiq_role, :worker)
      set_if_empty :sidekiq_configs, %w[sidekiq]  # sidekiq.yml

      set_if_empty :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
      set_if_empty :sidekiq_error_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }

      set_if_empty :sidekiq_config_files, ['sidekiq.yml']

      # Rbenv, Chruby, and RVM integration
      append :rbenv_map_bins, 'sidekiq', 'sidekiqctl'
      append :rvm_map_bins, 'sidekiq', 'sidekiqctl'
      append :chruby_map_bins, 'sidekiq', 'sidekiqctl'
      # Bundler integration
      append :bundle_bins, 'sidekiq', 'sidekiqctl'
    end
  end
end

require_relative 'sidekiq/systemd'
