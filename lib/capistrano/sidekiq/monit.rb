module Capistrano
  class Sidekiq::Monit < Capistrano::Plugin
    def define_tasks
      eval_rakefile File.expand_path('../../tasks/monit.rake', __FILE__)
    end

    def set_defaults
      set_if_empty :sidekiq_monit_conf_dir, '/etc/monit/conf.d'
      set_if_empty :sidekiq_monit_use_sudo, true
      set_if_empty :monit_bin, '/usr/bin/monit'
      set_if_empty :sidekiq_monit_default_hooks, true
      set_if_empty :sidekiq_monit_templates_path, 'config/deploy/templates'
    end

    def register_hooks
      before 'deploy:updating',  'sidekiq:monit:unmonitor'
      after  'deploy:published', 'sidekiq:monit:monitor'
    end
  end
end
