Capistrano::Configuration.instance.load do

  _cset(:sidekiq_default_hooks) { true }

  _cset(:sidekiq_pid) { File.join(shared_path, 'pids', 'sidekiq.pid') }
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

  if fetch(:sidekiq_default_hooks)
    before 'deploy:update_code', 'sidekiq:quiet'
    after 'deploy:stop', 'sidekiq:stop'
    after 'deploy:start', 'sidekiq:start'
    before 'deploy:restart', 'sidekiq:restart'
  end

  namespace :sidekiq do
    def for_each_process(sidekiq_role, &block)
      sidekiq_processes = fetch(:"#{ sidekiq_role }_processes") rescue 1
      sidekiq_processes.times do |idx|
        if idx.zero? && sidekiq_processes <= 1
          pid_file = fetch(:sidekiq_pid)
        else
          pid_file = fetch(:sidekiq_pid).gsub(/\.pid$/, "-#{idx}.pid")
        end
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
      su_user = fetch(:sidekiq_user)
      run cdm, roles: sidekiq_role, shell: "su - #{su_user}"
    end

    def quiet_process(pid_file, idx, sidekiq_role)
      run_as "if [ -d #{current_path} ] && [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then cd #{current_path} && #{fetch(:sidekiqctl_cmd)} quiet #{pid_file} ; else echo 'Sidekiq is not running'; fi"
    end

    def stop_process(pid_file, idx, sidekiq_role)
      run_as "if [ -d #{current_path} ] && [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then cd #{current_path} && #{fetch(:sidekiqctl_cmd)} stop #{pid_file} #{fetch :sidekiq_timeout} ; else echo 'Sidekiq is not running'; fi"
    end

    def start_process(pid_file, idx, sidekiq_role)
      args = []
      args.push "--index #{idx}"
      args.push "--pidfile #{pid_file}"
      args.push "--environment #{fetch(:sidekiq_env)}"
      args.push "--tag #{fetch(:sidekiq_tag)}" if fetch(:sidekiq_tag)
      args.push "--logfile #{fetch(:sidekiq_log)}" if fetch(:sidekiq_log)
      args.push "--config #{fetch(:sidekiq_config)}" if fetch(:sidekiq_config)
      args.push "--concurrency #{fetch(:sidekiq_concurrency)}" if fetch(:sidekiq_concurrency)
      fetch(:sidekiq_queue).each do |queue|
        args.push "--queue #{queue}"
      end if fetch(:sidekiq_queue)

      if process_options = fetch(:sidekiq_options_per_process)
        args.push process_options[idx]
      end

      args.push fetch(:sidekiq_options)

      if defined?(JRUBY_VERSION)
        args.push '>/dev/null 2>&1 &'
        logger.info 'Since JRuby doesn\'t support Process.daemon, Sidekiq will not be running as a daemon.'
      else
        args.push '--daemon'
      end

      run_as "if [ -d #{current_path} ] && [ ! -f #{pid_file} ] || ! kill -0 `cat #{pid_file}` > /dev/null 2>&1; then cd #{current_path} ; #{fetch(:sidekiq_cmd)} #{args.compact.join(' ')} ; else echo 'Sidekiq is already running'; fi", pty: false
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

  end
end
