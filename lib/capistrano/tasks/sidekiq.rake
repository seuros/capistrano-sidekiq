namespace :deploy do
  before :starting, :check_sidekiq_hooks do
    invoke 'sidekiq:add_default_hooks' if fetch(:sidekiq_default_hooks)
  end
end

namespace :sidekiq do
  task :add_default_hooks do
    after 'deploy:starting', 'sidekiq:quiet' if Rake::Task.task_defined?('sidekiq:quiet')
    after 'deploy:updated', 'sidekiq:stop'
    after 'deploy:reverted', 'sidekiq:stop'
    after 'deploy:published', 'sidekiq:start'
    after 'deploy:published', 'sidekiq:mark_deploy' if fetch(:sidekiq_mark_deploy, false)
    after 'deploy:failed', 'sidekiq:restart'
  end

  desc 'Mark deployment in Sidekiq metrics'
  task :mark_deploy do
    if fetch(:sidekiq_mark_deploy, false)
      on roles(fetch(:sidekiq_roles)) do
        within current_path do
          # Get deploy label - use custom label or git description
          deploy_label = fetch(:sidekiq_deploy_label) || begin
            capture(:git, 'log', '-1', '--format="%h %s"').strip
          rescue StandardError
            "#{fetch(:application)} #{fetch(:stage)} deploy"
          end
          
          info "Marking deployment in Sidekiq metrics: #{deploy_label}"
          
          # Create a Ruby script to mark the deployment
          mark_deploy_script = <<~RUBY
            require 'sidekiq/deploy'
            Sidekiq::Deploy.mark!(ARGV[0])
          RUBY
          
          # Execute the script with the deploy label
          execute :bundle, :exec, :ruby, '-e', mark_deploy_script, '--', deploy_label
        end
      end
    end
  end
end
