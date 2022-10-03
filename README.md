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
```

Configurable options - Please ensure you check your version's branch for the available settings - shown here with defaults:

```ruby
:sidekiq_roles => :worker
:sidekiq_default_hooks => true
:sidekiq_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
# single config
:sidekiq_config_files, ['sidekiq.yml']
# multiple configs
:sidekiq_config_files, ['sidekiq.yml', 'sidekiq-2.yml'] #  you can also set it per server
```

## Example

A sample application is provided to show how to use this gem at https://github.com/seuros/capistrano-example-app

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
