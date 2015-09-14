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
    :sidekiq_pid => File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid')
    :sidekiq_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
    :sidekiq_log => File.join(shared_path, 'log', 'sidekiq.log')
    :sidekiq_options => nil
    :sidekiq_require => nil
    :sidekiq_tag => nil
    :sidekiq_config => nil
    :sidekiq_queue => nil
    :sidekiq_timeout => 10
    :sidekiq_role => :app
    :sidekiq_processes => 1
    :sidekiq_options_per_process => nil
    :sidekiq_concurrency => nil
    :sidekiq_monit_templates_path => 'config/deploy/templates'
    :sidekiq_monit_use_sudo => true
    :sidekiq_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiq" # Only for capistrano2.5
    :sidekiqctl_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl" # Only for capistrano2.5
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

## Customizing the monit sidekiq templates

If you need change some config in redactor, you can

```
    bundle exec rails generate capistrano:sidekiq:monit:template

```

If your deploy user has no need in `sudo` for using monit, you can disable it as follows:

```ruby
set :sidekiq_monit_use_sudo, false
```

## Changelog
- 0.5.4: Add support for custom count of processes per host in monit task @okoriko
- 0.5.3: Custom count of processes per each host
- 0.5.0: Multiple processes @mrsimo
- 0.3.9: Restore daemon flag from Monit template
- 0.3.8:
        * Update monit template: use su instead of sudo / permit all Sidekiq options @bensie
        * Unmonitor monit while deploy @Saicheg
- 0.3.7:
        * fix capistrano2 task @tribble
        * Run Sidekiq as daemon from Monit @dpaluy
- 0.3.5: Added :sidekiq_tag for capistrano2 @OscarBarrett
- 0.3.4: fix bug in sidekiq:start for capistrano 2 task
- 0.3.3: sidekiq:restart after deploy:restart added to default hooks
- 0.3.2: :sidekiq_queue accept an array
- 0.3.1: Fix logs @rottman, add concurrency option support @ungsophy
- 0.3.0: Fix monit task @andreygerasimchuk
- 0.2.9: Check if current directory exist @alexdunae
- 0.2.8: Added :sidekiq_queue & :sidekiq_config
- 0.2.7: Signal usage @penso
- 0.2.6: sidekiq:start check if sidekiq is running
- 0.2.5: bug fixes
- 0.2.4: Fast deploy with :sidekiq_run_in_background
- 0.2.3: Added monit tasks (alpha)
- 0.2.0: Added sidekiq:rolling_restart - @jlecour

## Contributors

- [Jérémy Lecour] (https://github.com/jlecour)
- [Fabien Penso] (https://github.com/penso)
- [Alex Dunae] (https://github.com/alexdunae)
- [andreygerasimchuk] (https://github.com/andreygerasimchuk)
- [Saicheg] (https://github.com/Saicheg)
- [Alex Yakubenko] (https://github.com/alexyakubenko)
- [Robert Strobl] (https://github.com/rstrobl)
- [Eurico Doirado] (https://github.com/okoriko)
- [Huang Bin](https://github.com/hbin)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
