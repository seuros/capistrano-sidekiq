namespace :deploy do
  before :starting, :check_sidekiq_hooks do
    invoke 'sidekiq:add_default_hooks' if fetch(:sidekiq_default_hooks)
  end
end

namespace :sidekiq do
  task :add_default_hooks do
    after 'deploy:starting', 'sidekiq:quiet' if Rake::Task.task_defined?('sidekiq:quiet')
    after 'deploy:updated', 'sidekiq:stop'
    after 'deploy:published', 'sidekiq:start'
    after 'deploy:failed', 'sidekiq:restart'
  end
end
