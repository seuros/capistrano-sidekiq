[![Gem Version](https://badge.fury.io/rb/capistrano-sidekiq.svg)](http://badge.fury.io/rb/capistrano-sidekiq)
[![Dependency Status](https://gemnasium.com/seuros/capistrano-sidekiq.svg)](https://gemnasium.com/seuros/capistrano-sidekiq)

# Capistrano::Sidekiq

Sidekiq integration for Capistrano

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-sidekiq' , github: 'seuros/capistrano-sidekiq'

or:

    gem 'capistrano-sidekiq' , group: :development

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
    :sidekiq_default_hooks =>  true
    :sidekiq_pid =>  File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid')
    :sidekiq_env =>  fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
    :sidekiq_log =>  File.join(shared_path, 'log', 'sidekiq.log')
    :sidekiq_options =>  nil
    :sidekiq_require => nil
    :sidekiq_tag => nil
    :sidekiq_config => nil
    :sidekiq_queue => nil
    :sidekiq_timeout =>  10
    :sidekiq_role =>  :app
    :sidekiq_processes =>  1
    :sidekiq_concurrency => nil
    :sidekiq_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiq"  # Only for capistrano2.5
    :sidekiqctl_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl" # Only for capistrano2.5
```

There is a know bug that prevent sidekiq from starting when pty is true
```ruby
set :pty,  false
```
## Changelog
- 0.3.4: fix bug in sidekiq:start for capistrano 2 task
- 0.3.5: Added :sidekiq_tag for capistrano2 @OscarBarrett
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
