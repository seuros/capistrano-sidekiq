# frozen_string_literal: true

require 'capistrano/bundler'
require 'capistrano/plugin'

module Capistrano
  class Sidekiq < Capistrano::Plugin
    def define_tasks
      eval_rakefile File.expand_path('tasks/sidekiq.rake', __dir__)
    end

    def set_defaults
      set_if_empty :sidekiq_default_hooks, true

      set_if_empty :sidekiq_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:rake_env, fetch(:stage)))) }
      set_if_empty :sidekiq_roles, fetch(:sidekiq_role, :app)
      set_if_empty :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
      set_if_empty :sidekiq_error_log, -> { File.join(shared_path, 'log', 'sidekiq.error.log') }
      # Rbenv, Chruby, and RVM integration
      append :rbenv_map_bins, 'sidekiq', 'sidekiqctl'
      append :rvm_map_bins, 'sidekiq', 'sidekiqctl'
      append :chruby_map_bins, 'sidekiq', 'sidekiqctl'
      # Bundler integration
      append :bundle_bins, 'sidekiq', 'sidekiqctl'
    end
  end
end

require_relative 'sidekiq/helpers'
require_relative 'sidekiq/systemd'
require_relative 'sidekiq/monit'
