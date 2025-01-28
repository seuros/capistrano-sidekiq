# Capistrano::Sidekiq

[![Gem Version](https://badge.fury.io/rb/capistrano-sidekiq.svg)](http://badge.fury.io/rb/capistrano-sidekiq)

Sidekiq integration for Capistrano - providing systemd service management and deployment coordination.

## Installation

Add to your Gemfile:

```ruby
gem 'capistrano-sidekiq', group: :development
```

Then execute:

```bash
$ bundle install
```

## Setup

Add to your Capfile:

```ruby
# Capfile
require 'capistrano/sidekiq'
install_plugin Capistrano::Sidekiq  # Default sidekiq tasks
install_plugin Capistrano::Sidekiq::Systemd  # Systemd integration
```

## Configuration Options

### Basic Settings

```ruby
# config/deploy.rb
set :sidekiq_roles, :worker                  # Default role for Sidekiq processes
set :sidekiq_default_hooks, true             # Enable default deployment hooks
set :sidekiq_env, fetch(:rack_env, fetch(:rails_env, fetch(:stage)))  # Environment for Sidekiq processes

# Single config file
set :sidekiq_config_files, ['sidekiq.yml']   

# Multiple config files for different Sidekiq processes
set :sidekiq_config_files, ['sidekiq.yml', 'sidekiq-high-priority.yml']
```

### Advanced Configuration

```ruby
# Systemd service settings
set :service_unit_user, :system              # Run as system service (:system or :user)
set :systemctl_user, true                    # Run systemctl in user mode
set :sidekiq_service_unit_name, "custom_sidekiq_#{fetch(:stage)}"  # Custom service name

# Environment configuration
set :sidekiq_service_unit_env_files, ['/etc/environment']  # Environment files
set :sidekiq_service_unit_env_vars, [                      # Environment variables
  'RAILS_ENV=production',
  'MALLOC_ARENA_MAX=2'
]

# Logging configuration
set :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
set :sidekiq_error_log, -> { File.join(shared_path, 'log', 'sidekiq.error.log') }
```

### Per-Server Configuration

You can configure Sidekiq differently for specific servers:

```ruby
# config/deploy/production.rb
server 'worker1.example.com', 
  roles: [:worker], 
  sidekiq_config_files: ['sidekiq_1.yml'],
  sidekiq_user: 'custom_user'

server 'worker2.example.com', 
  roles: [:worker], 
  sidekiq_config_files: ['sidekiq_2.yml']
```

## Available Tasks

```bash
# View all available tasks
cap -T sidekiq

# Common commands
cap sidekiq:start              # Start Sidekiq
cap sidekiq:stop               # Stop Sidekiq (graceful shutdown)
cap sidekiq:restart            # Restart Sidekiq
cap sidekiq:quiet              # Quiet Sidekiq (stop processing new jobs)
cap sidekiq:install            # Install Sidekiq systemd service
cap sidekiq:uninstall          # Remove Sidekiq systemd service
cap sidekiq:enable             # Enable Sidekiq systemd service
cap sidekiq:disable            # Disable Sidekiq systemd service
```

## Working with Systemd Logs

View Sidekiq service logs using journalctl:

```bash
# View last 100 lines of logs
journalctl -u sidekiq_myapp_production -n 100

# Follow logs in real-time
journalctl -u sidekiq_myapp_production -f
```

## Log File Configuration

### Modern Systemd (v240+, e.g., Ubuntu 20.04+)

Log files are configured automatically using the `append:` functionality in the systemd service file.

### Legacy Systemd Systems

For systems with older Systemd versions where `append:` is not supported:

1. Sidekiq messages are sent to syslog by default
2. Configure system logger to filter Sidekiq messages

## Example Application

A complete example application demonstrating the usage of this gem is available at:
https://github.com/seuros/capistrano-example-app

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
