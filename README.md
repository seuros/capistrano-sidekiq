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
    install_plugin Capistrano::Sidekiq::Upstart  # tests needed
    # or  
    install_plugin Capistrano::Sidekiq::Monit  # tests needed
```


Configurable options, shown here with defaults:

```ruby
:sidekiq_roles => :app
:sidekiq_default_hooks => true
:sidekiq_pid => File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') # ensure this path exists in production before deploying.
:sidekiq_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
:sidekiq_log => File.join(shared_path, 'log', 'sidekiq.log')

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

## Known issues with Capistrano 3

There is a known bug that prevents sidekiq from starting when pty is true on Capistrano 3.
```ruby
set :pty,  false
```

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
