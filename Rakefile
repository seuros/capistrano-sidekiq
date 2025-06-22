require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  
  # Run unit tests in CI, all tests locally
  if ENV['CI']
    t.pattern = 'test/unit_test.rb'
  else
    t.pattern = 'test/**/*_test.rb'
  end
  
  t.verbose = true
end

Rake::TestTask.new(:unit) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = 'test/unit_test.rb'
  t.verbose = true
end

Rake::TestTask.new(:integration) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = 'test/deploy_test.rb'
  t.verbose = true
end

task default: :test
