# frozen_string_literal: true

require 'capistrano/bundler' unless ENV['TEST']
require 'capistrano/plugin'

module Capistrano
  module SidekiqCommon
    def compiled_template_sidekiq(from, role, config_file = 'sidekiq.yml')
      @role = role
      @config_file = config_file
      file = [
          "lib/capistrano/templates/#{from}-#{role.hostname}-#{fetch(:stage)}.rb",
          "lib/capistrano/templates/#{from}-#{role.hostname}.rb",
          "lib/capistrano/templates/#{from}-#{fetch(:stage)}.rb",
          "lib/capistrano/templates/#{from}.rb.erb",
          "lib/capistrano/templates/#{from}.rb",
          "lib/capistrano/templates/#{from}.erb",
          "config/deploy/templates/#{from}.rb.erb",
          "config/deploy/templates/#{from}.rb",
          "config/deploy/templates/#{from}.erb",
          File.expand_path("../templates/#{from}.erb", __FILE__),
          File.expand_path("../templates/#{from}.rb.erb", __FILE__)
      ].detect { |path| File.file?(path) }
      erb = File.read(file)
      StringIO.new(ERB.new(erb, trim_mode: '-').result(binding))
    end

    def template_sidekiq(from, to, role, config_file = 'sidekiq.yml')
      backend.upload! compiled_template_sidekiq(from, role, config_file), to
    end

    def expanded_bundle_command
      backend.capture(:echo, SSHKit.config.command_map[:bundle]).strip
    end

    def sidekiq_config
      "--config config/#{@config_file}" if @config_file != 'sidekiq.yml'
    end

    def sidekiq_switch_user(role, &block)
      su_user = sidekiq_user(role)
      if su_user == role.user
        yield
      else
        backend.as(su_user, &block)
      end
    end

    def sidekiq_user(role = nil)
      if role.nil?
        fetch(:sidekiq_user)
      else
        properties = role.properties
        return role.user unless properties
        
        properties.fetch(:sidekiq_user) || # local property for sidekiq only
          fetch(:sidekiq_user, nil) ||
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
      set_if_empty :sidekiq_configs, %w[sidekiq] # sidekiq.yml

      set_if_empty :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
      set_if_empty :sidekiq_error_log, -> { File.join(shared_path, 'log', 'sidekiq_error.log') }

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
