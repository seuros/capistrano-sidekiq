namespace :sidekiq do
  desc 'Quiet sidekiq (stop fetching new tasks from Redis)'
  task :quiet do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        sudo :service, fetch(:sidekiq_service_unit_name), :reload
      end
    end
  end

  desc 'Stop sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)'
  task :stop do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        sudo :service, fetch(:sidekiq_service_unit_name), :stop
      end
    end
  end

  desc 'Start sidekiq'
  task :start do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        sudo :service, fetch(:sidekiq_service_unit_name), :start
      end
    end
  end

  def switch_user(role)
    su_user = sidekiq_user(role)
    if su_user == role.user
      yield
    else
      as su_user do
        yield
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
