# Capistrano::Sidekiq

[![Gem Version](https://badge.fury.io/rb/capistrano-sidekiq.svg)](http://badge.fury.io/rb/capistrano-sidekiq)
[![COSS Compliant](https://img.shields.io/badge/COSS-compliant-green.svg)](https://github.com/contriboss/coss_spec)

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

### Shared Configuration with Other Gems

This gem follows the Capistrano convention of sharing common settings across multiple service gems (e.g., capistrano-puma, capistrano-sidekiq). The following settings are shared:

- `:service_unit_user` - Determines if services run as system or user services
- `:systemctl_bin` - Path to the systemctl binary
- `:lingering_user` - User for systemd lingering (for user services)
- `:service_unit_env_files` - Shared environment files
- `:service_unit_env_vars` - Shared environment variables

Each gem can override these with prefixed versions (e.g., `:sidekiq_systemctl_user`).

### Advanced Configuration

```ruby
# Shared systemd settings (can be used by multiple Capistrano gems like capistrano-puma)
set :service_unit_user, :user                # Run as user or system service (:system or :user)
set :systemctl_bin, '/bin/systemctl'         # Path to systemctl binary
set :lingering_user, 'deploy'                # User to enable lingering for (defaults to :user)

# Sidekiq-specific overrides (optional - defaults to shared settings above)
set :sidekiq_systemctl_user, :system         # Override service_unit_user for Sidekiq only
set :sidekiq_systemctl_bin, '/usr/bin/systemctl'  # Override systemctl_bin for Sidekiq only
set :sidekiq_service_unit_name, "custom_sidekiq_#{fetch(:stage)}"  # Custom service name
set :sidekiq_lingering_user, 'sidekiq'       # Override lingering user for Sidekiq only

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

You can configure Sidekiq differently for specific servers, allowing you to run different Sidekiq processes with different configurations on different servers.

#### Basic Per-Server Setup

```ruby
# config/deploy/production.rb
server 'worker1.example.com', 
  roles: [:worker], 
  sidekiq_config_files: ['sidekiq_high_priority.yml']

server 'worker2.example.com', 
  roles: [:worker], 
  sidekiq_config_files: ['sidekiq_low_priority.yml']
```

#### Advanced Per-Server Configuration

```ruby
# Different users and multiple processes per server
server 'worker1.example.com',
  roles: [:worker],
  sidekiq_config_files: ['sidekiq_critical.yml', 'sidekiq_default.yml'],
  sidekiq_user: 'sidekiq_critical',
  sidekiq_systemctl_user: :system  # Run as system service on this server

server 'worker2.example.com',
  roles: [:worker],
  sidekiq_config_files: ['sidekiq_batch.yml'],
  sidekiq_user: 'sidekiq_batch',
  sidekiq_service_unit_env_vars: ['MALLOC_ARENA_MAX=4']  # Server-specific env vars
```

#### How It Works

1. **Configuration Files**: Each server can have its own set of `sidekiq_config_files`
2. **Service Creation**: A separate systemd service is created for each config file
3. **Service Naming**: Services are named as `<app>_sidekiq_<stage>` for the default `sidekiq.yml`, or `<app>_sidekiq_<stage>.<config_name>` for additional configs
4. **Independent Control**: Each service can be started, stopped, and restarted independently

#### Example Configurations

**config/sidekiq_high_priority.yml:**
```yaml
:concurrency: 10
:queues:
  - [critical, 2]
  - [high, 1]
```

**config/sidekiq_low_priority.yml:**
```yaml
:concurrency: 5
:queues:
  - [low, 1]
  - [default, 1]
```

#### Deployment Commands

When using per-server configurations, Capistrano will:
- Install the appropriate services on each server during `cap production sidekiq:install`
- Start only the configured services on each server during `cap production sidekiq:start`
- Manage each server's services independently

You can also target specific servers:
```bash
cap production sidekiq:restart --hosts=worker1.example.com
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

## Systemd Integration

For detailed information about systemd integration, see [Systemd Integration Guide](docs/SYSTEMD_INTEGRATION.md).

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
