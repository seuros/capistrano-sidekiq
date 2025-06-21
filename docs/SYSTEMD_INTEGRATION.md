# Systemd Integration Guide

This document provides a comprehensive guide to using capistrano-sidekiq with systemd.

## Current State of Systemd Integration

As of version 3.0.0, capistrano-sidekiq provides full systemd integration with the following features:

- ✅ Automatic service file generation
- ✅ Support for both system and user services  
- ✅ Multiple process management
- ✅ Systemd lingering support
- ✅ Log file management
- ✅ Environment variable configuration
- ✅ Per-server configuration

## Requirements

- Systemd 240+ (for log file append support)
- Systemd 206+ (for basic functionality)
- Proper sudo permissions (for system services)

## Basic Setup

### 1. Add to Capfile

```ruby
require 'capistrano/sidekiq'
install_plugin Capistrano::Sidekiq
install_plugin Capistrano::Sidekiq::Systemd
```

### 2. Configure in deploy.rb

```ruby
# Basic configuration
set :sidekiq_roles, :worker
set :sidekiq_config_files, ['sidekiq.yml']

# Choose service type
set :service_unit_user, :user  # or :system
```

## Service Types

### User Services (Recommended)

User services run under a specific user account without requiring root privileges.

```ruby
set :service_unit_user, :user
```

**Advantages:**
- No sudo required for deployment
- Better security isolation
- Easier permission management

**Requirements:**
- Systemd lingering must be enabled (handled automatically)
- User must have a systemd user instance running

### System Services

System services run as traditional system-wide services.

```ruby
set :service_unit_user, :system
```

**Advantages:**
- Starts automatically on boot
- No lingering configuration needed
- Traditional service management

**Requirements:**
- Sudo permissions for service installation
- Proper User= directive in service file

## Service File Generation

The gem automatically generates systemd service files based on your configuration. The template includes:

- Proper service dependencies
- Watchdog support (10 second timeout)
- Automatic restart on failure
- Log file configuration
- Environment setup

### Generated Service File Location

- **User services**: `~/.config/systemd/user/<app>_sidekiq_<stage>.service`
- **System services**: `/etc/systemd/system/<app>_sidekiq_<stage>.service`

### Service Naming Convention

- Default config (`sidekiq.yml`): `<app>_sidekiq_<stage>`
- Additional configs: `<app>_sidekiq_<stage>.<config_name>`

Example:
- `myapp_sidekiq_production` (for sidekiq.yml)
- `myapp_sidekiq_production.sidekiq_critical` (for sidekiq_critical.yml)

## Multiple Process Support

Unlike older versions that used process indices, v3.0.0 uses separate config files for multiple processes:

```ruby
# Old approach (no longer supported)
set :sidekiq_processes, 4  # This doesn't work anymore

# New approach
set :sidekiq_config_files, [
  'sidekiq.yml',
  'sidekiq_critical.yml',
  'sidekiq_low_priority.yml'
]
```

Each config file creates a separate systemd service that can be managed independently.

## Environment Configuration

### Environment Files

Load environment variables from files:

```ruby
set :sidekiq_service_unit_env_files, [
  '/etc/environment',
  "#{shared_path}/.env"
]
```

### Direct Environment Variables

Set environment variables directly in the service:

```ruby
set :sidekiq_service_unit_env_vars, [
  'RAILS_ENV=production',
  'MALLOC_ARENA_MAX=2'
]
```

## Logging

### Modern Systemd (v240+)

Logs are automatically configured to append to files:

```ruby
set :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
set :sidekiq_error_log, -> { File.join(shared_path, 'log', 'sidekiq.error.log') }
```

### Viewing Logs

```bash
# View service logs
journalctl --user -u myapp_sidekiq_production -f

# View file logs
tail -f /path/to/shared/log/sidekiq.log
```

## Deployment Workflow

### Initial Setup

```bash
cap production sidekiq:install   # Creates and enables services
cap production deploy            # Deploys and starts services
```

### Updates

```bash
cap production deploy            # Automatically restarts services
```

### Manual Control

```bash
cap production sidekiq:start
cap production sidekiq:stop
cap production sidekiq:restart
cap production sidekiq:quiet
```

## Troubleshooting

### Service Won't Start

1. Check service status:
   ```bash
   systemctl --user status myapp_sidekiq_production
   ```

2. Check logs:
   ```bash
   journalctl --user -u myapp_sidekiq_production -n 100
   ```

3. Verify lingering (for user services):
   ```bash
   loginctl show-user $USER | grep Linger
   ```

### Permission Issues

For user services:
- Ensure the deploy user owns all necessary directories
- Check that lingering is enabled

For system services:
- Verify sudo permissions
- Check service file ownership

### Service Stops After Logout

This indicates lingering is not properly configured. The gem should handle this automatically, but you can manually enable:

```bash
sudo loginctl enable-linger $USER
```

## Migration from Older Versions

### From capistrano-sidekiq v2.x

1. Remove old configuration:
   ```ruby
   # Remove these
   set :sidekiq_processes, 4
   set :sidekiq_options_per_process, [...]
   ```

2. Update to new configuration:
   ```ruby
   # Add these
   set :sidekiq_config_files, ['sidekiq.yml']
   install_plugin Capistrano::Sidekiq::Systemd
   ```

3. Uninstall old services and install new ones:
   ```bash
   cap production sidekiq:uninstall
   cap production sidekiq:install
   ```

### From Monit/Upstart

1. Stop and remove old services
2. Install systemd plugin
3. Run `cap production sidekiq:install`

## Best Practices

1. **Use User Services**: Unless you have specific requirements, user services are recommended
2. **One Config Per Purpose**: Create separate config files for different job types
3. **Monitor Services**: Set up monitoring for service health
4. **Resource Limits**: Configure systemd resource limits if needed
5. **Logging**: Use structured logging and centralized log management

## Advanced Configuration

### Custom Service Templates

Create your own service template:

```ruby
set :sidekiq_service_templates_path, 'config/deploy/templates'
```

Place your template at: `config/deploy/templates/sidekiq.service.capistrano.erb`

### Resource Limits

Add to your custom template:

```
[Service]
# Memory limit
MemoryLimit=2G
# CPU quota
CPUQuota=80%
# Restart limits
StartLimitBurst=3
StartLimitInterval=60s
```

### Dependencies

Add service dependencies:

```
[Unit]
After=redis.service postgresql.service
Requires=redis.service
```

## Compatibility

- **Sidekiq 6.0+**: Full support (removed deprecated features)
- **Systemd 240+**: Full support including log append
- **Systemd 206+**: Basic support (logs via journal only)
- **Ruby 2.5+**: Minimum required version

## Known Limitations

1. No support for systemd template units (sidekiq@.service)
2. Each config file creates a separate service
3. No automatic process count scaling
4. Requires manual lingering setup on some systems

These limitations are by design to provide better control and visibility over individual Sidekiq processes.