require 'yaml'
require 'erb'

namespace :load do
  task :defaults do
    set :sidekiq_default_hooks, -> { true }

    set :sidekiq_pid, -> { nil }
    set :sidekiq_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
    set :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
    set :sidekiq_timeout, -> { 10 }
    set :sidekiq_role, -> { :app }
    set :sidekiq_processes, -> { 1 }
    set :sidekiq_options_per_process, -> { nil }
    set :sidekiq_user, -> { nil }
    # Rbenv, Chruby, and RVM integration
    set :rbenv_map_bins, fetch(:rbenv_map_bins).to_a.concat(%w(sidekiq sidekiqctl))
    set :rvm_map_bins, fetch(:rvm_map_bins).to_a.concat(%w(sidekiq sidekiqctl))
    set :chruby_map_bins, fetch(:chruby_map_bins).to_a.concat(%w{ sidekiq sidekiqctl })
    # Bundler integration
    set :bundle_bins, fetch(:bundle_bins).to_a.concat(%w(sidekiq sidekiqctl))
  end
end

namespace :deploy do
  before :starting, :check_sidekiq_hooks do
    invoke 'sidekiq:add_default_hooks' if fetch(:sidekiq_default_hooks)
  end
  after :publishing, :restart_sidekiq do
    invoke 'sidekiq:restart' if fetch(:sidekiq_default_hooks)
  end
end

namespace :sidekiq do
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
      # This line handles backwards-compatability
      # where we must check the `app_processes` option
      # to get the number of sidekiq processes for hosts with the :app role.
      processes = fetch(:"#{ role }_processes") unless sidekiq_specific_role?(role)
      processes ||= fetch_role_specific_values(:processes, role) do |key|
        fetch(key)
      end
      processes.times do |idx|
        append_idx = true
        pid_file = sidekiq_fetch(:pid, role, idx)

        if !pid_file && sidekiq_fetch(:config, role, idx)
          config_file = sidekiq_fetch(:config, role, idx)
          conf = YAML.load(ERB.new(IO.read(config_file)).result)
          if conf
            if conf[sidekiq_fetch(:env, role, idx).to_sym]
              pid_file = conf[sidekiq_fetch(:env, role, idx).to_sym][:pidfile]
            end
            pid_file ||= conf[:pidfile]
          end

          append_idx = false if pid_file
        end

        pid_file ||= File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid')

        pid_file = pid_file.gsub(/\.pid$/, "-#{idx}.pid") if append_idx
        pids.push pid_file
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

  def stop_sidekiq(pid_file, role, idx)
    if fetch(:stop_sidekiq_in_background, fetch(:sidekiq_run_in_background))
      if sidekiq_fetch(:use_signals, role, idx)
        background "kill -TERM `cat #{pid_file}`"
      else
        background :sidekiqctl, 'stop', "#{pid_file}", sidekiq_fetch(:timeout, role, idx)
      end
    else
      execute :sidekiqctl, 'stop', "#{pid_file}", sidekiq_fetch(:timeout, role, idx)
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

  def start_sidekiq(pid_file, role, idx = 0)
    args = []
    args.push "--index #{idx}"
    args.push "--pidfile #{pid_file}"
    args.push "--environment #{sidekiq_fetch(:env, role, idx)}"
    args.push "--logfile #{sidekiq_fetch(:log, role, idx)}" if sidekiq_fetch(:log, role, idx)
    args.push "--require #{sidekiq_fetch(:require, role, idx)}" if sidekiq_fetch(:require, role, idx)
    args.push "--tag #{sidekiq_fetch(:tag, role, idx)}" if sidekiq_fetch(:tag, role, idx)
    Array(sidekiq_fetch_queue(role, idx)).each do |queue|
      args.push "--queue #{queue}"
    end
    args.push "--config #{sidekiq_fetch(:config, role, idx)}" if sidekiq_fetch(:config, role, idx)
    args.push "--concurrency #{sidekiq_fetch(:concurrency, role, idx)}" if sidekiq_fetch(:concurrency, role, idx)
    if process_options = fetch(:sidekiq_options_per_process)
      args.push process_options[idx]
    end
    # use sidekiq_options for special options
    args.push sidekiq_fetch(:options, role, idx) if sidekiq_fetch(:options, role, idx)

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

  task :add_default_hooks do
    after 'deploy:starting', 'sidekiq:quiet'
    after 'deploy:updated', 'sidekiq:stop'
    after 'deploy:reverted', 'sidekiq:stop'
    after 'deploy:published', 'sidekiq:start'
  end

  desc 'Quiet sidekiq (stop processing new tasks)'
  task :quiet do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        if test("[ -d #{release_path} ]") # fixes #11
          for_each_process(true) do |pid_file, idx|
            if pid_process_exists?(pid_file)
              quiet_sidekiq(pid_file)
            end
          end
        end
      end
    end
  end

  desc 'Stop sidekiq'
  task :stop do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        if test("[ -d #{release_path} ]")
          for_each_process(true) do |pid_file, idx|
            if pid_process_exists?(pid_file)
              stop_sidekiq(pid_file, role, idx)
            end
          end
        end
      end
    end
  end

  desc 'Start sidekiq'
  task :start do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        for_each_process do |pid_file, idx|
          start_sidekiq(pid_file, role, idx) unless pid_process_exists?(pid_file)
        end
      end
    end
  end

  desc 'Restart sidekiq'
  task :restart do
    invoke 'sidekiq:stop'
    invoke 'sidekiq:start'
  end

  desc 'Rolling-restart sidekiq'
  task :rolling_restart do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        for_each_process(true) do |pid_file, idx|
          if pid_process_exists?(pid_file)
            stop_sidekiq(pid_file)
          end
          start_sidekiq(pid_file, role, idx)
        end
      end
    end
  end

  # Delete any pid file not in use
  task :cleanup do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        for_each_process do |pid_file, idx|
          if pid_file_exists?(pid_file)
            execute "rm #{pid_file}" unless pid_process_exists?(pid_file)
          end
        end
      end
    end
  end

  # TODO : Don't start if all processes are off, raise warning.
  desc 'Respawn missing sidekiq processes'
  task :respawn do
    invoke 'sidekiq:cleanup'
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        for_each_process do |pid_file, idx|
          unless pid_file_exists?(pid_file)
            start_sidekiq(pid_file, role, idx)
          end
        end
      end
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
end
