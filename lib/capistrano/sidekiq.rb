version = begin
  Capistrano::VERSION
rescue NameError
  Capistrano::Version
end

if Gem::Version.new(version).release >= Gem::Version.new('3.0.0')
  load File.expand_path('../tasks/sidekiq.cap', __FILE__)
else
  require_relative 'tasks/capistrano2'
end
