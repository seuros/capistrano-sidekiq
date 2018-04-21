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
# Sidekiq options
:sidekiq_config => nil # if you have a config/sidekiq.yml, do not forget to set this.
:sidekiq_pid => File.join(shared_path, 'tmp', 'pids', 'sidekiq-0.pid') # if you specify a pidfile in your sidekiq_config file that value will be used as the default.
:sidekiq_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
:sidekiq_log => File.join(shared_path, 'log', 'sidekiq.log')
:sidekiq_require => nil
:sidekiq_tag => nil
:sidekiq_queue => nil
:sidekiq_concurrency => nil
:sidekiq_options => nil

:sidekiq_timeout => 10 # Used when stopping sidekiq

# Capistrano options
:sidekiq_default_hooks => true
:sidekiq_role => :app
:sidekiq_processes => 1
:sidekiq_user => nil #user to run sidekiq as
:start_sidekiq_in_background => false
:stop_sidekiq_in_background => false
:sidekiq_run_in_background => false # like setting both :start_ and :stop_sidekiq_in_background to true
:sidekiq_use_signals => false # if :stop_sidekiq_in_background is true, use signals for quite & stop
:sidekiq_monit_templates_path => 'config/deploy/templates'
:sidekiq_monit_use_sudo => true

# Options only for Capistrano 2.5
:sidekiq_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiq"
:sidekiqctl_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl"

# Deprecated Sidekiq options
:sidekiq_options_per_process => nil
```

There is a known bug that prevents sidekiq from starting when pty is true on Capistrano 3.
```ruby
set :pty,  false
```

## Multiple processes

You can configure sidekiq to start with multiple processes. Just set the `sidekiq_processes` option.

You can also customize the configuration for each process by giving your various sidekiq config options Array values.

```ruby
set :sidekiq_processes,  2
set :sidekiq_log, 'log/background.log'
set :sidekiq_config, [
                       'config/sidekiq/high.yml',
                       'config/sidekiq/low.yml'
                     ]
set :sidekiq_queue,  [
                       [:high],
                       [:default, :low]
                     ]
```

In this example the first process will start with the following options:
* log: 'log/background.log'
* config: 'config/sidekiq/high.yml'
* queue: 'high'

And the second sidekiq process will start with the following options:
* log: 'log/background.log'
* config: 'config/sidekiq/low.yml'
* queue: 'low' AND 'default'

## Different options per host

You can configure different sidekiq options for different hosts using roles:

```ruby
set :sidekiq_role, [:web, :sidekiq_worker]
set :sidekiq_log, 'log/background.log'

set :sidekiq_web_processes, 1
set :sidekiq_web_config, 'config/sidekiq/web.yml'

set :sidekiq_worker_processes, 2
set :sidekiq_worker_config, [
                              'config/sidekiq/worker_one.yml',
                              'config/sidekiq/worker_two.yml'
                            ]

server 'web1.example.com', roles: [:web]
server 'bg1.example.com',  roles: [:sidekiq_worker]
```

In this example the web1 host will have one process with the following options:
* log: 'log/background.log'
* config: 'config/sidekiq/web.yml'

The bg1 host will have two processes. The first will have the following options:
* log: 'log/background.log'
* config: 'config/sidekiq/worker_one.yml'

The second sidekiq process on bg1 will start with the following options:
* log: 'log/background.log'
* config: 'config/sidekiq/worker_two.yml'

## Customizing the monit sidekiq templates

If you need to change some config in redactor, you can

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
