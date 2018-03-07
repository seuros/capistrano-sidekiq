namespace :load do
  task :defaults do
    set :sidekiq_default_hooks, true

    set :sidekiq_pid, -> { File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') }
    set :sidekiq_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
    set :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
    set :sidekiq_timeout, 10
    set :sidekiq_roles, :app
    set :sidekiq_processes, 1
    set :sidekiq_options_per_process, nil
    set :sidekiq_user, nil
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
  task :add_default_hooks do
    after 'deploy:starting',  'sidekiq:quiet'
    after 'deploy:updated',   'sidekiq:stop'
    after 'deploy:reverted',  'sidekiq:stop'
    after 'deploy:published', 'sidekiq:start'
  end

  desc 'Quiet sidekiq (stop fetching new tasks from Redis)'
  task :quiet do
    on roles fetch(:sidekiq_roles) do |role|
      switch_user(role) do
        if test("[ -d #{release_path} ]")
          each_process_with_index(reverse: true) do |pid_file, idx|
            if pid_file_exists?(pid_file) && process_exists?(pid_file)
              quiet_sidekiq(pid_file)
            end
          end
        end
      end
    end
  end

  desc 'Stop sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)'
  task :stop do
    on roles fetch(:sidekiq_roles) do |role|
      switch_user(role) do
        if test("[ -d #{release_path} ]")
          each_process_with_index(reverse: true) do |pid_file, idx|
            if pid_file_exists?(pid_file) && process_exists?(pid_file)
              stop_sidekiq(pid_file)
            end
          end
        end
      end
    end
  end

  desc 'Start sidekiq'
  task :start do
    on roles fetch(:sidekiq_roles) do |role|
      switch_user(role) do
        each_process_with_index do |pid_file, idx|
          unless pid_file_exists?(pid_file) && process_exists?(pid_file)
            start_sidekiq(pid_file, idx)
          end
        end
      end
    end
  end

  desc 'Restart sidekiq'
  task :restart do
    invoke! 'sidekiq:stop'
    invoke 'sidekiq:start'
  end

  desc 'Rolling-restart sidekiq'
  task :rolling_restart do
    on roles fetch(:sidekiq_roles) do |role|
      switch_user(role) do
        each_process_with_index(true) do |pid_file, idx|
          if pid_file_exists?(pid_file) && process_exists?(pid_file)
            stop_sidekiq(pid_file)
          end
          start_sidekiq(pid_file, idx)
        end
      end
    end
  end

  desc 'Delete any pid file not in use'
  task :cleanup do
    on roles fetch(:sidekiq_roles) do |role|
      switch_user(role) do
        each_process_with_index do |pid_file, idx|
          unless process_exists?(pid_file)
            if pid_file_exists?(pid_file)
              execute "rm #{pid_file}"
            end
          end
        end
      end
    end
  end

  # TODO: Don't start if all processes are off, raise warning.
  desc 'Respawn missing sidekiq processes'
  task :respawn do
    invoke 'sidekiq:cleanup'
    on roles fetch(:sidekiq_roles) do |role|
      switch_user(role) do
        each_process_with_index do |pid_file, idx|
          unless pid_file_exists?(pid_file)
            start_sidekiq(pid_file, idx)
          end
        end
      end
    end
  end

  def each_process_with_index(reverse: false)
    _pid_files = pid_files
    _pid_files.reverse! if reverse
    _pid_files.each_with_index do |pid_file, idx|
      within release_path do
        yield(pid_file, idx)
      end
    end
  end

  def pid_files
    sidekiq_roles = Array(fetch(:sidekiq_roles))
    sidekiq_roles.select! { |role| host.roles.include?(role) }
    sidekiq_roles.flat_map do |role|
      processes = fetch(:"#{ role }_processes") ||
                  fetch(:sidekiq_config_files_per_role)&.dig(role)&.size ||
                  fetch(:sidekiq_processes)
      Array.new(processes) { |idx| fetch(:sidekiq_pid).gsub(/\.pid$/, "-#{role}-#{idx}.pid") }
    end
  end

  def pid_file_exists?(pid_file)
    test(*("[ -f #{pid_file} ]").split(' '))
  end

  def process_exists?(pid_file)
    test(*("kill -0 $( cat #{pid_file} )").split(' '))
  end

  def quiet_sidekiq(pid_file)
    begin
      execute :sidekiqctl, 'quiet', "#{pid_file}"
    rescue SSHKit::Command::Failed
      # If gems are not installed (first deploy) and sidekiq_default_hooks is active
      warn 'sidekiqctl not found (ignore if this is the first deploy)'
    end
  end

  def stop_sidekiq(pid_file)
    execute :sidekiqctl, 'stop', "#{pid_file}", fetch(:sidekiq_timeout)
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

    if process_config_file = fetch(:sidekiq_config_files_per_role)
      process_role = pid_file.match(/(\w+)-(\d).pid$/)[1].to_s.to_sym
      process_id = pid_file.match(/(\w+)-(\d).pid$/)[2].to_i
      args.push "-C #{release_path}/config/#{process_config_file[process_role][process_id]}.yml"
    end
    # use sidekiq_options for special options
    args.push fetch(:sidekiq_options) if fetch(:sidekiq_options)

    if defined?(JRUBY_VERSION)
      args.push '>/dev/null 2>&1 &'
      warn 'Since JRuby doesn\'t support Process.daemon, Sidekiq will not be running as a daemon.'
    else
      args.push '--daemon'
    end

    execute :sidekiq, args.compact.join(' ')
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
    properties.fetch(:sidekiq_user) || # local property for sidekiq only
    fetch(:sidekiq_user) ||
    properties.fetch(:run_as) || # global property across multiple capistrano gems
    role.user
  end
end
