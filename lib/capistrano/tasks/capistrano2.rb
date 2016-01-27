require 'yaml'
require 'erb'

Capistrano::Configuration.instance.load do

  _cset(:sidekiq_default_hooks) { true }

  _cset(:sidekiq_pid) { nil }
  _cset(:sidekiq_env) { fetch(:rack_env, fetch(:rails_env, 'production')) }
  _cset(:sidekiq_tag) { nil }
  _cset(:sidekiq_log) { File.join(shared_path, 'log', 'sidekiq.log') }

  _cset(:sidekiq_config) { "#{current_path}/config/sidekiq.yml" }
  _cset(:sidekiq_options) { nil }
  _cset(:sidekiq_queue) { nil }
  _cset(:sidekiq_concurrency) { nil }

  _cset(:sidekiq_cmd) { "#{fetch(:bundle_cmd, 'bundle')} exec sidekiq" }
  _cset(:sidekiqctl_cmd) { "#{fetch(:bundle_cmd, 'bundle')} exec sidekiqctl" }

  _cset(:sidekiq_timeout) { 10 }
  _cset(:sidekiq_role) { :app }

  _cset(:sidekiq_processes) { 1 }
  _cset(:sidekiq_options_per_process) { nil }

  _cset(:sidekiq_user) { nil }

  if fetch(:sidekiq_default_hooks)
    before 'deploy:update_code', 'sidekiq:quiet'
    after 'deploy:stop', 'sidekiq:stop'
    after 'deploy:start', 'sidekiq:start'
    before 'deploy:restart', 'sidekiq:restart'
  end

  namespace :sidekiq do
    def for_each_process(sidekiq_role, &block)
      # This line handles backwards-compatability
      # where we must check the `app_processes` option
      # to get the number of sidekiq processes for hosts with the :app role.
      processes = fetch(:"#{ role }_processes") unless sidekiq_specific_role?(role) rescue nil
      processes ||= fetch_role_specific_values(:processes, role) do |key|
        fetch(key) rescue nil
      end
      processes.times do |idx|
        append_idx = true
        pid_file = sidekiq_fetch(:pid, sidekiq_role, idx)

        if !pid_file && sidekiq_fetch(:config, sidekiq_role, idx)
          config_file = sidekiq_fetch(:config, sidekiq_role, idx)
          conf = YAML.load(ERB.new(IO.read(config_file)).result)
          if conf
            if conf[sidekiq_fetch(:env, sidekiq_role, idx).to_sym]
              pid_file = conf[sidekiq_fetch(:env, sidekiq_role, idx).to_sym][:pidfile]
            end
            pid_file ||= conf[:pidfile]
          end

          append_idx = false if pid_file
        end

        pid_file ||= File.join(shared_path, 'pids', 'sidekiq.pid')

        pid_file = pid_file.gsub(/\.pid$/, "-#{idx}.pid") if append_idx
        yield(pid_file, idx)
      end
    end

    def for_each_role
      sidekiq_roles = fetch(:sidekiq_role)

      sidekiq_roles = if sidekiq_roles.respond_to?(:to_ary)
                        sidekiq_roles.to_ary
                      else
                        [sidekiq_roles]
                      end

      sidekiq_roles.to_ary.each do |sidekiq_role|
        puts "executing on ##{ sidekiq_role }" if sidekiq_roles.size > 1
        yield(sidekiq_role)
      end
    end

    def run_as(cmd)
      opts = {
        roles: sidekiq_role
      }
      su_user = fetch(:sidekiq_user)
      opts[:shell] = "su - #{su_user}" if su_user
      run cmd, opts
    end

    def quiet_process(pid_file, idx, sidekiq_role)
      run_as "if [ -d #{current_path} ] && [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then cd #{current_path} && #{fetch(:sidekiqctl_cmd)} quiet #{pid_file} ; else echo 'Sidekiq is not running'; fi"
    end

    def stop_process(pid_file, idx, sidekiq_role)
      run_as "if [ -d #{current_path} ] && [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then cd #{current_path} && #{fetch(:sidekiqctl_cmd)} stop #{pid_file} #{sidekiq_fetch(:timeout, sidekiq_role, idx)} ; else echo 'Sidekiq is not running'; fi"
    end

    def start_process(pid_file, idx, sidekiq_role)
      args = []
      args.push "--index #{idx}"
      args.push "--pidfile #{pid_file}"
      args.push "--environment #{sidekiq_fetch(:env, sidekiq_role, idx)}"
      args.push "--tag #{sidekiq_fetch(:tag, sidekiq_role, idx)}" if sidekiq_fetch(:tag, sidekiq_role, idx)
      args.push "--logfile #{sidekiq_fetch(:log, sidekiq_role, idx)}" if sidekiq_fetch(:log, sidekiq_role, idx)
      args.push "--config #{sidekiq_fetch(:config, sidekiq_role, idx)}" if sidekiq_fetch(:config, sidekiq_role, idx)
      args.push "--concurrency #{sidekiq_fetch(:concurrency, sidekiq_role, idx)}" if sidekiq_fetch(:concurrency, sidekiq_role, idx)
      Array(sidekiq_fetch_queue(sidekiq_role, idx)).each do |queue|
        args.push "--queue #{queue}"
      end

      if process_options = fetch(:sidekiq_options_per_process)
        args.push process_options[idx]
      end

      args.push sidekiq_fetch(:options, sidekiq_role, idx) if sidekiq_fetch(:options, sidekiq_role, idx)

      if defined?(JRUBY_VERSION)
        args.push '>/dev/null 2>&1 &'
        logger.info 'Since JRuby doesn\'t support Process.daemon, Sidekiq will not be running as a daemon.'
      else
        args.push '--daemon'
      end

      run_as "if [ -d #{current_path} ] && [ ! -f #{pid_file} ] || ! kill -0 `cat #{pid_file}` > /dev/null 2>&1; then cd #{current_path} ; #{fetch(:sidekiq_cmd)} #{args.compact.join(' ')} ; else echo 'Sidekiq is already running'; fi"
    end

    desc 'Quiet sidekiq (stop accepting new work)'
    task :quiet, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      for_each_role do |sidekiq_role|
        for_each_process(sidekiq_role) do |pid_file, idx|
          quiet_process(pid_file, idx, sidekiq_role)
        end
      end
    end

    desc 'Stop sidekiq'
    task :stop, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      for_each_role do |sidekiq_role|
        for_each_process(sidekiq_role) do |pid_file, idx|
          stop_process(pid_file, idx, sidekiq_role)
        end
      end
    end

    desc 'Start sidekiq'
    task :start, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      for_each_role do |sidekiq_role|
        for_each_process(sidekiq_role) do |pid_file, idx|
          start_process(pid_file, idx, sidekiq_role)
        end
      end
    end

    desc 'Rolling-restart sidekiq'
    task :rolling_restart, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      for_each_role do |sidekiq_role|
        for_each_process(sidekiq_role) do |pid_file, idx|
          stop_process(pid_file, idx, sidekiq_role)
          start_process(pid_file, idx, sidekiq_role)
        end
      end
    end

    desc 'Restart sidekiq'
    task :restart, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      stop
      start
    end

    # Fetch a value for a given config, role, and idx
    # Returns the most specific value it can find,
    # falling back to less & less specific values
    # until it ultimately returns a deafult value.
    def sidekiq_fetch(config_name, role, idx)
      fetch_role_specific_values(config_name, role, idx) do |key, idx|
        case fetch(key)
        when Array
          fetch(key)[idx]
        else
          fetch(key)
        end
      end
    end

    # Fetch an Array of queue values for a given role, and idx
    # We have to be a bit careful
    # because sidekiq_queue already supports Array values
    # which are used to tell a single sidekiq process
    # to monitor multiple queues.
    # Therefore if you want per-process sidekiq_queue values
    # you must use nested Arrays
    #
    # Examples
    #
    #    # In this case, both processes will monitor the fast AND slow queues
    #    set :sidekiq_queue [:fast, :slow]
    #    set :sidekiq_processes 2
    #
    #    # In this case, the first process will monitor the fast queue
    #    # and the second process will monitor the slow queue
    #    set :sidekiq_queue [[:fast], [:slow]]
    #    set :sidekiq_processes 2
    #
    #    # In this case, the first process will monitor the fast queue
    #    # and the second process will monitor the medium AND slow queues
    #    set :sidekiq_queue [:fast, [:medium, :slow]]
    #    set :sidekiq_processes 2
    #
    def sidekiq_fetch_queue(role, idx)
      fetch_role_specific_values('queue', role, idx) do |key, idx|
        next unless queues = fetch(key)

        queues = Array(queues)
        # If at least one of the queues is an Array of queues
        # we assume the intention is that this is an nested Array of Arrays
        if queues.detect{ |val| val.is_a?(Array) }
          queues[idx]
        else
          queues
        end
      end
    end

    # Fetch a value for a given config, role
    # Returns the most specific value it can find,
    # falling back to less & less specific values
    # until it ultimately returns a deafult value.
    def fetch_role_specific_values(config_name, role, *args)
      keys_to_check = []
      if sidekiq_specific_role?(role)
        keys_to_check << :"#{ role }_#{ config_name }"
      else
        keys_to_check << :"sidekiq_#{ role }_#{ config_name }"
      end
      keys_to_check << :"sidekiq_#{ config_name }"

      val = nil
      keys_to_check.each do |key|
        val ||= yield(key, *args)
      end
      val
    end

    def sidekiq_specific_role?(role)
      role.to_s =~ /^sidekiq_/
    end

  end
end
