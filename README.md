[![Gem Version](https://badge.fury.io/rb/capistrano-sidekiq.svg)](http://badge.fury.io/rb/capistrano-sidekiq)

# Capistrano::Sidekiq

Sidekiq integration for Capistrano

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-sidekiq', github: 'seuros/capistrano-sidekiq'

or:

    gem 'capistrano-sidekiq', group: :development

And then execute:

    $ bundle


## Usage
```ruby
# Capfile
require 'capistrano/sidekiq'
require 'capistrano/sidekiq/monit' #to require monit tasks # Only for capistrano3
```


Configurable options, shown here with defaults:

```ruby
:sidekiq_default_hooks => true
:sidekiq_pid => File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') # ensure this path exists in production before deploying.
:sidekiq_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
:sidekiq_log => File.join(shared_path, 'log', 'sidekiq.log')
:sidekiq_options => nil
:sidekiq_require => nil
:sidekiq_tag => nil
:sidekiq_config => nil # if you have a config/sidekiq.yml, do not forget to set this. 
:sidekiq_queue => nil
:sidekiq_timeout => 10
:sidekiq_roles => :app
:sidekiq_processes => 1
:sidekiq_options_per_process => nil
:sidekiq_concurrency => nil
# sidekiq monit
:sidekiq_monit_templates_path => 'config/deploy/templates'
:sidekiq_monit_conf_dir => '/etc/monit/conf.d'
:sidekiq_monit_use_sudo => true
:monit_bin => '/usr/bin/monit'
:sidekiq_monit_default_hooks => true
:sidekiq_monit_group => nil
:sidekiq_service_name => "sidekiq_#{fetch(:application)}_#{fetch(:sidekiq_env)}" + (index ? "_#{index}" : '') 

:sidekiq_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiq" # Only for capistrano2.5
:sidekiqctl_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl" # Only for capistrano2.5
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

## Multiple processes

You can configure sidekiq to start with multiple processes. Just set the proper amount in `sidekiq_processes`.

You can also customize the configuration for every process. If you want to do that, just set
`sidekiq_options_per_process` with an array of the configuration options that you want in string format.
This example should boot the first process with the queue `high` and the second one with the queues `default`
and `low`:

```ruby
set :sidekiq_processes, 2
set :sidekiq_options_per_process, ["--queue high", "--queue default --queue low"]
```

## Different number of processes per role

You can configure how many processes you want to run on each host next way:

```ruby
set :sidekiq_roles, [:sidekiq_small, :sidekiq_big]
set :sidekiq_small_processes, 1
set :sidekiq_big_processes, 4
server 'example-small.com', roles: [:sidekiq_small]
server 'example-big.com', roles: [:sidekiq_big]
```

## Integration with systemd

Set init system to systemd in the cap deploy config:

```ruby
set :init_system, :systemd
```

Enable lingering for systemd user account

```
loginctl enable-linger USERACCOUNT
```

Install systemd.service template file and enable the service with:

```
bundle exec cap sidekiq:install
```

Default name for the service file is `sidekiq-stage.service`. This can be changed as needed, for example:

```ruby
set :service_unit_name, "sidekiq-#{fetch(:application)}-#{fetch(:stage)}.service"
```

## Integration with upstart

Set init system to upstart in the cap deploy config:

```ruby
set :init_system, :upstart
```

Set upstart service name:
```ruby
set :upstart_service_name, 'sidekiq'
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
