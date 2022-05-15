lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/sidekiq/version'

Gem::Specification.new do |spec|
  spec.name = 'capistrano-sidekiq'
  spec.version = Capistrano::SidekiqVERSION
  spec.authors = ['Abdelkader Boudih']
  spec.email = ['terminale@gmail.com']
  spec.summary = %q{Sidekiq integration for Capistrano}
  spec.description = %q{Sidekiq integration for Capistrano}
  spec.homepage = 'https://github.com/seuros/capistrano-sidekiq'
  spec.license = 'LGPL-3.0'

  spec.required_ruby_version     = '>= 2.0.0'
  spec.files = `git ls-files`.split($/)
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '>= 3.9.0'
  spec.add_dependency 'capistrano-bundler'
  spec.add_dependency 'sidekiq', '>= 6.0'
end
