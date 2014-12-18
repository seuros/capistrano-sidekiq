Capistrano::Configuration.instance.load do

  _cset(:sidekiq_default_hooks) { true }

  _cset(:sidekiq_pid) { File.join(shared_path, 'pids', 'sidekiq.pid') }
  _cset(:sidekiq_env) { fetch(:rack_env, fetch(:rails_env, 'production')) }
  _cset(:sidekiq_tag) { nil }
  _cset(:sidekiq_log) { File.join(shared_path, 'log', 'sidekiq.log') }

  _cset(:sidekiq_config) { "#{current_path}/config/sidekiq.yml" }
  _cset(:sidekiq_options) { nil }
  _cset(:sidekiq_queue) { nil }

  _cset(:sidekiq_cmd) { "#{fetch(:bundle_cmd, 'bundle')} exec sidekiq" }
  _cset(:sidekiqctl_cmd) { "#{fetch(:bundle_cmd, 'bundle')} exec sidekiqctl" }

  _cset(:sidekiq_timeout) { 10 }
  _cset(:sidekiq_role) { :app }
  _cset(:sidekiq_processes) { 1 }

  if fetch(:sidekiq_default_hooks)
    before 'deploy:update_code', 'sidekiq:quiet'
    after 'deploy:stop', 'sidekiq:stop'
    after 'deploy:start', 'sidekiq:start'
    before 'deploy:restart', 'sidekiq:restart'
  end

  namespace :sidekiq do
    def for_each_process(&block)
      fetch(:sidekiq_processes).times do |idx|
        if idx.zero? && fetch(:sidekiq_processes) <= 1
          pid_file = fetch(:sidekiq_pid)
        else
          pid_file = fetch(:sidekiq_pid).gsub(/\.pid$/, "-#{idx}.pid")
        end
        yield(pid_file, idx)
      end
    end

    def quiet_process(pid_file, idx)
      run "if [ -d #{current_path} ] && [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then cd #{current_path} && #{fetch(:sidekiqctl_cmd)} quiet #{pid_file} ; else echo 'Sidekiq is not running'; fi"
    end

    def stop_process(pid_file, idx)
      run "if [ -d #{current_path} ] && [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then cd #{current_path} && #{fetch(:sidekiqctl_cmd)} stop #{pid_file} #{fetch :sidekiq_timeout} ; else echo 'Sidekiq is not running' && if [ -f #{pid_file} ] ; then rm #{pid_file} ; fi ; fi"
    end

    def start_process(pid_file, idx)
      args = []
      args.push "--index #{idx}"
      args.push "--pidfile #{pid_file}"
      args.push "--environment #{fetch(:sidekiq_env)}"
      args.push "--tag #{fetch(:sidekiq_tag)}" if fetch(:sidekiq_tag)
      args.push "--logfile #{fetch(:sidekiq_log)}" if fetch(:sidekiq_log)
      args.push "--config #{fetch(:sidekiq_config)}" if fetch(:sidekiq_config)
      fetch(:sidekiq_queue).each do |queue|
        args.push "--queue #{queue}"
      end if fetch(:sidekiq_queue)
      args.push fetch(:sidekiq_options)

      if defined?(JRUBY_VERSION)
        args.push '>/dev/null 2>&1 &'
        logger.info 'Since JRuby doesn\'t support Process.daemon, Sidekiq will not be running as a daemon.'
      else
        args.push '--daemon'
      end

      run "if [ -d #{current_path} ] && [ ! -f #{pid_file} ] || ! kill -0 `cat #{pid_file}` > /dev/null 2>&1; then cd #{current_path} ; #{fetch(:sidekiq_cmd)} #{args.compact.join(' ')} ; else echo 'Sidekiq is already running'; fi", pty: false
    end

    desc 'Quiet sidekiq (stop accepting new work)'
    task :quiet, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      for_each_process do |pid_file, idx|
        quiet_process(pid_file, idx)
      end
    end

    desc 'Stop sidekiq'
    task :stop, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      for_each_process do |pid_file, idx|
        stop_process(pid_file, idx)
      end
    end

    desc 'Start sidekiq'
    task :start, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      for_each_process do |pid_file, idx|
        start_process(pid_file, idx)
      end
    end

    desc 'Rolling-restart sidekiq'
    task :rolling_restart, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      for_each_process do |pid_file, idx|
        stop_process(pid_file, idx)
        start_process(pid_file, idx)
      end
    end

    desc 'Restart sidekiq'
    task :restart, roles: lambda { fetch(:sidekiq_role) }, on_no_matching_servers: :continue do
      stop
      start
    end

  end
end
