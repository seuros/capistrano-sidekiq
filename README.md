[![Gem Version](https://badge.fury.io/rb/capistrano-sidekiq.svg)](http://badge.fury.io/rb/capistrano-sidekiq)
[![Dependency Status](https://gemnasium.com/seuros/capistrano-sidekiq.svg)](https://gemnasium.com/seuros/capistrano-sidekiq)

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
:sidekiq_role => :app
:sidekiq_processes => 1
:sidekiq_options_per_process => nil
:sidekiq_concurrency => nil
:sidekiq_monit_templates_path => 'config/deploy/templates'
:sidekiq_monit_conf_dir => '/etc/monit/conf.d'
:sidekiq_monit_use_sudo => true
:monit_bin => '/usr/bin/monit'
:sidekiq_monit_default_hooks => true
:sidekiq_service_name => "sidekiq_#{fetch(:application)}_#{fetch(:sidekiq_env)}"
:sidekiq_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiq" # Only for capistrano2.5
:sidekiqctl_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl" # Only for capistrano2.5
:sidekiq_user => nil #user to run sidekiq as
```

There is a known bug that prevents sidekiq from starting when pty is true on Capistrano 3.
```ruby
set :pty,  false
```

## Multiple processes

You can configure sidekiq to start with multiple processes. Just set the proper amount in `sidekiq_processes`.

You can also customize the configuration for every process. If you want to do that, just set
`sidekiq_options_per_process` with an array of the configuration options that you want in string format.
This example should boot the first process with the queue `high` and the second one with the queues `default`
and `low`:

```ruby
set :sidekiq_options_per_process, ["--queue high", "--queue default --queue low"]
```

## Different number of processes per host

You can configure how many processes you want to run on each host next way:

```ruby
set :sidekiq_role, [:sidekiq_small, :sidekiq_big]
set :sidekiq_small_processes, 1
set :sidekiq_big_processes, 4
server 'example-small.com', roles: [:sidekiq_small]
server 'example-big.com', roles: [:sidekiq_big]
```

## Different configs per host

You can configure what config file you want to use on each host next way:

```ruby
set :sidekiq_example_small_com_config, "config/small_sidekiq.yml"
set :sidekiq_example_big_com_config, "config/big_sidekiq.yml"
server 'example-small.com', roles: [:app]
server 'example-big.com', roles: [:app]
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
