git_plugin = self
namespace :sidekiq do
  namespace :monit do

    desc 'Config Sidekiq monit-service'
    task :config do
      on roles(fetch(:sidekiq_role)) do |role|
        @role = role
        git_plugin.upload_sidekiq_template 'sidekiq_monit', "#{fetch(:tmp_dir)}/monit.conf", @role

        mv_command = "mv #{fetch(:tmp_dir)}/monit.conf #{fetch(:sidekiq_monit_conf_dir)}/#{sidekiq_service_name}.conf"
        git_plugin.sudo_if_needed mv_command

        git_plugin.sudo_if_needed "#{fetch(:monit_bin)} reload"
      end
    end

    desc 'Monitor Sidekiq monit-service'
    task :monitor do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          begin
            git_plugin.sudo_if_needed "#{fetch(:monit_bin)} monitor #{sidekiq_service_name(idx)}"
          rescue
            invoke 'sidekiq:monit:config'
            git_plugin.sudo_if_needed "#{fetch(:monit_bin)} monitor #{sidekiq_service_name(idx)}"
          end
        end
      end
    end

    desc 'Unmonitor Sidekiq monit-service'
    task :unmonitor do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          begin
            git_plugin.sudo_if_needed "#{fetch(:monit_bin)} unmonitor #{sidekiq_service_name(idx)}"
          rescue
            # no worries here
          end
        end
      end
    end

    desc 'Start Sidekiq monit-service'
    task :start do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          git_plugin.sudo_if_needed "#{fetch(:monit_bin)} start #{sidekiq_service_name(idx)}"
        end
      end
    end

    desc 'Stop Sidekiq monit-service'
    task :stop do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          git_plugin.sudo_if_needed "#{fetch(:monit_bin)} stop #{sidekiq_service_name(idx)}"
        end
      end
    end

    desc 'Restart Sidekiq monit-service'
    task :restart do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          git_plugin.sudo_if_needed"#{fetch(:monit_bin)} restart #{sidekiq_service_name(idx)}"
        end
      end
    end
  end
end
