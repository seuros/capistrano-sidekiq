lock '~> 3.17.0'

set :application, 'capistrano_sidekiq_test'
set :repo_url, 'https://github.com/seuros/capistrano-sidekiq.git'
set :branch, 'master'
set :deploy_to, '/var/www/capistrano_sidekiq_test'
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Sidekiq configuration
set :sidekiq_roles, :worker
set :sidekiq_config, 'config/sidekiq.yml'
set :sidekiq_service_unit_user, :user

namespace :deploy do
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end