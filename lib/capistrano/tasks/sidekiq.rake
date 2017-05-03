git_plugin = self

namespace :sidekiq do
  desc 'Quiet sidekiq (stop processing new tasks)'
  task :quiet do
    on roles fetch(:sidekiq_role) do |role|
      git_plugin.switch_user(role) do
        if test("[ -d #{release_path} ]") # fixes #11
          git_plugin.for_each_process(true) do |pid_file, idx|
            if  git_plugin.pid_process_exists?(pid_file)
              git_plugin.quiet_sidekiq(pid_file)
            end
          end
        end
      end
    end
  end

  desc 'Stop sidekiq'
  task :stop do
    on roles fetch(:sidekiq_role) do |role|
      git_plugin.switch_user(role) do
        if test("[ -d #{release_path} ]")
          git_plugin.for_each_process(true) do |pid_file, idx|
            if  git_plugin.pid_process_exists?(pid_file)
              git_plugin.stop_sidekiq(pid_file)
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
      git_plugin.switch_user(role) do
        git_plugin.for_each_process do |pid_file, idx|
          git_plugin.start_sidekiq(pid_file, idx) unless  git_plugin.pid_process_exists?(pid_file)
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
      git_plugin.switch_user(role) do
        git_plugin.for_each_process(true) do |pid_file, idx|
          if  git_plugin.pid_process_exists?(pid_file)
            git_plugin.stop_sidekiq(pid_file)
          end
          git_plugin.start_sidekiq(pid_file, idx)
        end
      end
    end
  end

  # Delete any pid file not in use
  task :cleanup do
    on roles fetch(:sidekiq_role) do |role|
      git_plugin.switch_user(role) do
        git_plugin.for_each_process do |pid_file, idx|
          if  git_plugin.pid_file_exists?(pid_file)
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
      git_plugin.switch_user(role) do
        git_plugin.for_each_process do |pid_file, idx|
          unless  git_plugin.pid_file_exists?(pid_file)
            git_plugin.start_sidekiq(pid_file, idx)
          end
        end
      end
    end
  end
end
