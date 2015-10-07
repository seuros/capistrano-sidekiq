namespace :load do
  task :defaults do
    set :sidekiq_monit_conf_dir, '/etc/monit/conf.d'
    set :sidekiq_monit_use_sudo, true
    set :monit_bin, '/usr/bin/monit'
    set :sidekiq_monit_default_hooks, true
    set :sidekiq_monit_templates_path, 'config/deploy/templates'
  end
end

namespace :deploy do
  before :starting, :check_sidekiq_monit_hooks do
    if fetch(:sidekiq_default_hooks) && fetch(:sidekiq_monit_default_hooks)
      invoke 'sidekiq:monit:add_default_hooks'
    end
  end
end

namespace :sidekiq do
  namespace :monit do

    task :add_default_hooks do
      before 'deploy:updating',  'sidekiq:monit:unmonitor'
      after  'deploy:published', 'sidekiq:monit:monitor'
    end

    desc 'Config Sidekiq monit-service'
    task :config do
      on roles(fetch(:sidekiq_role)) do |role|
        @role = role
        upload_sidekiq_template 'sidekiq_monit', "#{fetch(:tmp_dir)}/monit.conf", @role

        mv_command = "mv #{fetch(:tmp_dir)}/monit.conf #{fetch(:sidekiq_monit_conf_dir)}/#{sidekiq_service_name}.conf"
        sudo_if_needed mv_command

        sudo_if_needed "#{fetch(:monit_bin)} reload"
      end
    end

    desc 'Monitor Sidekiq monit-service'
    task :monitor do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          begin
            sudo_if_needed "#{fetch(:monit_bin)} monitor #{sidekiq_service_name(idx)}"
          rescue
            invoke 'sidekiq:monit:config'
            sudo_if_needed "#{fetch(:monit_bin)} monitor #{sidekiq_service_name(idx)}"
          end
        end
      end
    end

    desc 'Unmonitor Sidekiq monit-service'
    task :unmonitor do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          begin
            sudo_if_needed "#{fetch(:monit_bin)} unmonitor #{sidekiq_service_name(idx)}"
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
          sudo_if_needed "#{fetch(:monit_bin)} start #{sidekiq_service_name(idx)}"
        end
      end
    end

    desc 'Stop Sidekiq monit-service'
    task :stop do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          sudo_if_needed "#{fetch(:monit_bin)} stop #{sidekiq_service_name(idx)}"
        end
      end
    end

    desc 'Restart Sidekiq monit-service'
    task :restart do
      on roles(fetch(:sidekiq_role)) do
        fetch(:sidekiq_processes).times do |idx|
          sudo_if_needed"#{fetch(:monit_bin)} restart #{sidekiq_service_name(idx)}"
        end
      end
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

    def sidekiq_require
      if fetch(:sidekiq_require)
        "--require #{fetch(:sidekiq_require)}"
      end
    end

    def sidekiq_logfile
      if fetch(:sidekiq_log)
        "--logfile #{fetch(:sidekiq_log)}"
      end
    end

    def sudo_if_needed(command)
      send(use_sudo? ? :sudo : :execute, command)
    end

    def use_sudo?
      fetch(:sidekiq_monit_use_sudo)
    end

  end
end
