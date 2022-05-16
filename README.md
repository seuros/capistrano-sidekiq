[![Gem Version](https://badge.fury.io/rb/capistrano-sidekiq.svg)](http://badge.fury.io/rb/capistrano-sidekiq)

# Capistrano::Sidekiq

Sidekiq integration for Capistrano

## Installation

    gem 'capistrano-sidekiq', group: :development

And then execute:

    $ bundle


## Usage
```ruby
    # Capfile

    require 'capistrano/sidekiq'
    install_plugin Capistrano::Sidekiq  # Default sidekiq tasks
    # Then select your service manager
    install_plugin Capistrano::Sidekiq::Systemd
    # or
    install_plugin Capistrano::Sidekiq::Monit  # tests needed
```


Configurable options - Please ensure you check your version's branch for the available settings - shown here with defaults:

```ruby
:sidekiq_roles => :app
:sidekiq_default_hooks => true
:sidekiq_pid => File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') # ensure this path exists in production before deploying.
:sidekiq_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
:sidekiq_log => File.join(shared_path, 'log', 'sidekiq.log')
# single config
:sidekiq_config => 'config/sidekiq.yml'
# per process config - process 1, process 2,... etc.
:sidekiq_config => [
    'config/sidekiq_config1.yml',
    'config/sidekiq_config2.yml'
]
:sidekiq_concurrency => 25
:sidekiq_queue => %w(default high low)
:sidekiq_processes => 1 # number of systemd processes you want to start

# sidekiq systemd options
:sidekiq_service_templates_path => 'config/deploy/templates' # to be used if a custom template is needed (filaname should be #{fetch(:sidekiq_service_unit_name)}.service.capistrano.erb or sidekiq.service.capistrano.erb
:sidekiq_service_unit_name => 'sidekiq'
:sidekiq_service_unit_user => :user # :system
:sidekiq_enable_lingering => true
:sidekiq_lingering_user => nil

# sidekiq monit
:sidekiq_monit_templates_path => 'config/deploy/templates'
:sidekiq_monit_conf_dir => '/etc/monit/conf.d'
:sidekiq_monit_use_sudo => true
:monit_bin => '/usr/bin/monit'
:sidekiq_monit_default_hooks => true
:sidekiq_monit_group => nil
:sidekiq_service_name => "sidekiq_#{fetch(:application)}"

:sidekiq_user => nil #user to run sidekiq as
```
See `capistrano/sidekiq/helpers.rb` for other undocumented configuration settings.

## Bundler

If you'd like to prepend `bundle exec` to your sidekiq and sidekiqctl calls, modify the SSHKit command maps
in your deploy.rb file:
```ruby
SSHKit.config.command_map[:sidekiq] = "bundle exec sidekiq"
SSHKit.config.command_map[:sidekiqctl] = "bundle exec sidekiqctl"
```


## Customizing the monit sidekiq templates

If you need change some config in redactor, you can

```
bundle exec rails generate capistrano:sidekiq:monit:template
```

If your deploy user has no need in `sudo` for using monit, you can disable it as follows:

```ruby
set :sidekiq_monit_use_sudo, false
```

## Configuring the log files on systems with less recent Systemd versions

The template used by this project assumes a recent version of Systemd (v240+, e.g. Ubuntu 20.04).

On systems with a less recent version, the `append:` functionality is not supported, and the Sidekiq log messages are sent to the syslog.

It's possible to workaround this limitation by configuring the system logger to filter the Sidekiq messages; see [wiki](/../../wiki/Configuring-append-mode-log-files-via-Syslog-NG).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
