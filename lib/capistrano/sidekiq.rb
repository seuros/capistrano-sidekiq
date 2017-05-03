require 'capistrano/bundler'
require "capistrano/plugin"

module Capistrano
  class Sidekiq < Capistrano::Plugin
    def define_tasks
      eval_rakefile File.expand_path('../tasks/sidekiq.rake', __FILE__)
    end

    def set_defaults
      set_if_empty :sidekiq_pid, -> { File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') }
      set_if_empty :sidekiq_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
      set_if_empty :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
      set_if_empty :sidekiq_timeout, 10
      set_if_empty :sidekiq_role, :app
      set_if_empty :sidekiq_processes, 1
      set_if_empty :sidekiq_options_per_process, nil
      set_if_empty :sidekiq_user, nil

      # Rbenv, Chruby, and RVM integration
      append :rbenv_map_bins, 'sidekiq', 'sidekiqctl'
      append :rvm_map_bins, 'sidekiq', 'sidekiqctl'
      append :chruby_map_bins, 'sidekiq', 'sidekiqctl'

      # Bundler integration
      append :bundle_bins, 'sidekiq', 'sidekiqctl'
    end

    def register_hooks
      after 'deploy:starting', 'sidekiq:quiet'
      after 'deploy:updated', 'sidekiq:stop'
      after 'deploy:reverted', 'sidekiq:stop'
      after 'deploy:published', 'sidekiq:start'
    end


    def for_each_process(reverse = false, &block)
      pids = processes_pids
      pids.reverse! if reverse
      pids.each_with_index do |pid_file, idx|
        within release_path do
          yield(pid_file, idx)
        end
      end
    end

    def processes_pids
      pids = []
      sidekiq_roles = Array(fetch(:sidekiq_role))
      sidekiq_roles.each do |role|
        next unless host.roles.include?(role)
        processes = fetch(:"#{ role }_processes") || fetch(:sidekiq_processes)
        processes.times do |idx|
          pids.push fetch(:sidekiq_pid).gsub(/\.pid$/, "-#{idx}.pid")
        end
      end

      pids
    end

    def pid_process_exists?(pid_file)
      pid_file_exists?(pid_file) and test(*("kill -0 $( cat #{pid_file} )").split(' '))
    end

    def pid_file_exists?(pid_file)
      test(*("[ -f #{pid_file} ]").split(' '))
    end

    def stop_sidekiq(pid_file)
      if fetch(:stop_sidekiq_in_background, fetch(:sidekiq_run_in_background))
        if fetch(:sidekiq_use_signals)
          background "kill -TERM `cat #{pid_file}`"
        else
          background :sidekiqctl, 'stop', "#{pid_file}", fetch(:sidekiq_timeout)
        end
      else
        execute :sidekiqctl, 'stop', "#{pid_file}", fetch(:sidekiq_timeout)
      end
    end

    def quiet_sidekiq(pid_file)
      if fetch(:sidekiq_use_signals)
        background "kill -USR1 `cat #{pid_file}`"
      else
        begin
          execute :sidekiqctl, 'quiet', "#{pid_file}"
        rescue SSHKit::Command::Failed
          # If gems are not installed eq(first deploy) and sidekiq_default_hooks as active
          warn 'sidekiqctl not found (ignore if this is the first deploy)'
        end
      end
    end

    def start_sidekiq(pid_file, idx = 0)
      args = []
      args.push "--index #{idx}"
      args.push "--pidfile #{pid_file}"
      args.push "--environment #{fetch(:sidekiq_env)}"
      args.push "--logfile #{fetch(:sidekiq_log)}" if fetch(:sidekiq_log)
      args.push "--require #{fetch(:sidekiq_require)}" if fetch(:sidekiq_require)
      args.push "--tag #{fetch(:sidekiq_tag)}" if fetch(:sidekiq_tag)
      Array(fetch(:sidekiq_queue)).each do |queue|
        args.push "--queue #{queue}"
      end
      args.push "--config #{fetch(:sidekiq_config)}" if fetch(:sidekiq_config)
      args.push "--concurrency #{fetch(:sidekiq_concurrency)}" if fetch(:sidekiq_concurrency)
      if process_options = fetch(:sidekiq_options_per_process)
        args.push process_options[idx]
      end
      # use sidekiq_options for special options
      args.push fetch(:sidekiq_options) if fetch(:sidekiq_options)

      if defined?(JRUBY_VERSION)
        args.push '>/dev/null 2>&1 &'
        warn 'Since JRuby doesn\'t support Process.daemon, Sidekiq will not be running as a daemon.'
      else
        args.push '--daemon'
      end

      if fetch(:start_sidekiq_in_background, fetch(:sidekiq_run_in_background))
        background :sidekiq, args.compact.join(' ')
      else
        execute :sidekiq, args.compact.join(' ')
      end
    end

    def switch_user(role, &block)
      su_user = sidekiq_user(role)
      if su_user == role.user
        block.call
      else
        as su_user do
          block.call
        end
      end
    end

    def sidekiq_user(role)
      properties = role.properties
      properties.fetch(:sidekiq_user) ||               # local property for sidekiq only
          fetch(:sidekiq_user) ||
          properties.fetch(:run_as) || # global property across multiple capistrano gems
          role.user
    end

    def upload_sidekiq_template(from, to, role)
      template = sidekiq_template(from, role)
      upload!(StringIO.new(ERB.new(template).result(binding)), to)
    end

    def sidekiq_template(name, role)
      @role = role
      local_template_directory = fetch(:sidekiq_monit_templates_path)

      search_paths = [
          "#{name}-#{role.hostname}-#{fetch(:stage)}.erb",
          "#{name}-#{role.hostname}.erb",
          "#{name}-#{fetch(:stage)}.erb",
          "#{name}.erb"
      ].map { |filename| File.join(local_template_directory, filename) }

      global_search_path = File.expand_path(
          File.join(*%w[.. .. .. generators capistrano sidekiq monit templates], "#{name}.conf.erb"),
          __FILE__
      )

      search_paths << global_search_path

      template_path = search_paths.detect { |path| File.file?(path) }
      File.read(template_path)
    end

    def sidekiq_service_name(index=nil)
      fetch(:sidekiq_service_name, "sidekiq_#{fetch(:application)}_#{fetch(:sidekiq_env)}") + index.to_s
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
      if fetch(:sidekiq_log)
        "--logfile #{fetch(:sidekiq_log)}"
      end
    end

    def sidekiq_require
      if fetch(:sidekiq_require)
        "--require #{fetch(:sidekiq_require)}"
      end
    end

    def sidekiq_options_per_process
      fetch(:sidekiq_options_per_process) || []
    end

    def sudo_if_needed(command)
      send(use_sudo? ? :sudo : :execute, command)
    end

    def use_sudo?
      fetch(:sidekiq_monit_use_sudo)
    end
  end
end

require 'capistrano/sidekiq/monit'