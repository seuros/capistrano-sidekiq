require "bundler/gem_tasks"
require 'github_changelog_generator/task'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'seuros'
  config.project = 'capistrano-sidekiq'
  config.issues = false
  config.future_release = '2.3.0'
end
