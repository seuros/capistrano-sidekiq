# frozen_string_literal: true

lock '~> 3.20'

set :application, 'capistrano_sidekiq_test'
# The test container mounts this checkout read-only at /src, so the deploy
# exercises the committed state of the current branch, not GitHub master.
set :repo_url, 'file:///src'
set :branch, ENV.fetch('CAP_BRANCH') { `git rev-parse --abbrev-ref HEAD`.strip }
set :repo_tree, 'test/app'
set :deploy_to, '/var/www/capistrano_sidekiq_test'
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Sidekiq configuration
set :sidekiq_roles, :worker
set :sidekiq_config, 'config/sidekiq.yml'
# Not a Rails app: tell Sidekiq which file defines the jobs.
set :sidekiq_command_args, -> { "-e #{fetch(:sidekiq_env)} -r ./app.rb" }
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
