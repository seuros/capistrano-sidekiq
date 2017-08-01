if Gem::Specification.find_by_name('capistrano').version >= Gem::Version.new('3.0.0')
  load File.expand_path('../tasks/sidekiq.rake', __FILE__)
else
  require_relative 'tasks/capistrano2'
end
require 'parallel'
