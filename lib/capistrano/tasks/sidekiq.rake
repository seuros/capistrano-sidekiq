namespace :sidekiq do
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
              stop_sidekiq(pid_file)
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
        for_each_process do |pid_file, idx|
          start_sidekiq(pid_file, idx) unless pid_process_exists?(pid_file)
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
end
