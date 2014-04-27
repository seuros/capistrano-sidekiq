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
    :sidekiq_timeout =>  10
    :sidekiq_role =>  :app
    :sidekiq_processes =>  1
    :sidekiq_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiq"  # Only for capistrano2.5
    :sidekiqctl_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl" # Only for capistrano2.5
```
## Changelog
- 0.2.7: Signal usage @penso
- 0.2.6: sidekiq:start check if sidekiq is running
- 0.2.5: bug fixes
- 0.2.4: Fast deploy with :sidekiq_run_in_background
- 0.2.3: Added monit tasks (alpha)
- 0.2.0: Added sidekiq:rolling_restart - @jlecour

## Contributors

- [Jérémy Lecour] (https://github.com/jlecour)
- [Fabien Penso] (https://github.com/penso)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
