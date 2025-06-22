# frozen_string_literal: true

require_relative 'lib/capistrano/sidekiq/version'

Gem::Specification.new do |spec|
  spec.name = 'capistrano-sidekiq'
  spec.version = Capistrano::SidekiqVERSION
  spec.authors = ['Abdelkader Boudih']
  spec.email = ['terminale@gmail.com']
  spec.description = 'Sidekiq integration for Capistrano'
  spec.summary = 'Sidekiq integration for Capistrano'
  spec.homepage = 'https://github.com/seuros/capistrano-sidekiq'
  spec.license = 'LGPL-3.0'

  spec.required_ruby_version = '>= 3.2.0'

  spec.files = Dir.glob('lib/**/*') + %w[README.md CHANGELOG.md LICENSE.txt]
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '>= 3.9.0'
  spec.add_dependency 'capistrano-bundler'
  spec.add_dependency 'sidekiq', '>= 7.0'
  
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-minitest', '~> 0.30'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  
  spec.post_install_message = '
    Version 3.0.0 is a major release. Please see README.md, breaking changes are listed in CHANGELOG.md
  '
end
