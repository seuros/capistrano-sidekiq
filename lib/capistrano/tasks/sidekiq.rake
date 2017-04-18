namespace :load do
  task :defaults do
    set :sidekiq_default_hooks, -> { true }

    set :sidekiq_pid, -> { File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') }
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
    # Init system integration
    set :init_system, -> { nil }
    # systemd integration
    set :service_unit_name, "sidekiq-#{fetch(:stage)}.service"
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
        case fetch(:init_system)
        when :systemd
          execute :systemctl, "--user", "reload", fetch(:service_unit_name), raise_on_non_zero_exit: false
        else
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
  end

  desc 'Stop sidekiq'
  task :stop do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        case fetch(:init_system)
        when :systemd
          execute :systemctl, "--user", "stop", fetch(:service_unit_name)
        else
          if test("[ -d #{release_path} ]")
            for_each_process(true) do |pid_file, idx|
              if pid_process_exists?(pid_file)
                stop_sidekiq(pid_file)
              end
            end
          end
        end
      end
    end
    Rake::Task["sidekiq:stop"].reenable
  end

  desc 'Start sidekiq'
  task :start do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        case fetch(:init_system)
        when :systemd
          execute :systemctl, "--user", "start", fetch(:service_unit_name)
        else
          for_each_process do |pid_file, idx|
            start_sidekiq(pid_file, idx) unless pid_process_exists?(pid_file)
          end
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
          start_sidekiq(pid_file, idx)
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
            start_sidekiq(pid_file, idx)
          end
        end
      end
    end
  end

  task :install do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        case fetch(:init_system)
        when :systemd
          create_systemd_template
          execute :systemctl, "--user", "enable", fetch(:service_unit_name)
        end
      end
    end
  end

  task :uninstall do
    on roles fetch(:sidekiq_role) do |role|
      switch_user(role) do
        case fetch(:init_system)
        when :systemd
          execute :systemctl, "--user", "disable", fetch(:service_unit_name)
          execute :rm, File.join(fetch(:service_unit_path, fetch_systemd_unit_path),fetch(:service_unit_name))
        end
      end
    end
  end

  def fetch_systemd_unit_path
    home_dir = capture :pwd
    File.join(home_dir, ".config", "systemd", "user")
  end

  def create_systemd_template
    search_paths = [
      File.expand_path(
        File.join(*%w[.. .. .. generators capistrano sidekiq systemd templates sidekiq.service.capistrano.erb]),
        __FILE__
      ),
    ]
    template_path = search_paths.detect {|path| File.file?(path)}
    template = File.read(template_path)
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    execute :mkdir, "-p", systemd_path
    upload!(
      StringIO.new(ERB.new(template).result(binding)),
      "#{systemd_path}/#{fetch :service_unit_name}"
    )
    execute :systemctl, "--user", "daemon-reload"
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
