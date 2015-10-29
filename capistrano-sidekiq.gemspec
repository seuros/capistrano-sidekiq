# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/sidekiq/version'

Gem::Specification.new do |spec|
  spec.name = 'capistrano-sidekiq'
  spec.version = Capistrano::Sidekiq::VERSION
  spec.authors = ['Abdelkader Boudih']
  spec.email = ['terminale@gmail.com']
  spec.summary = %q{Sidekiq integration for Capistrano}
  spec.description = %q{Sidekiq integration for Capistrano}
  spec.homepage = 'https://github.com/seuros/capistrano-sidekiq'
  spec.license = 'LGPL-3.0'

  spec.required_ruby_version     = '>= 1.9.3'
  spec.files = `git ls-files`.split($/)
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano'
  spec.add_dependency 'sidekiq', '>= 3.4'
end
