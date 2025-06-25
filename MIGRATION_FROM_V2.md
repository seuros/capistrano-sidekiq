# Migration Guide: From v2.x to v3.x

This guide helps you migrate from capistrano-sidekiq v2.x to v3.x.

## Breaking Changes

### 1. Monit Support Removed

**v3.0.0 removed monit support completely.** The gem now only supports systemd for service management.

#### Before (v2.x with Monit):
```ruby
# Capfile
require 'capistrano/sidekiq'
install_plugin Capistrano::Sidekiq
install_plugin Capistrano::Sidekiq::Monit  # No longer available
```

#### After (v3.x with Systemd only):
```ruby
# Capfile
require 'capistrano/sidekiq'
install_plugin Capistrano::Sidekiq
install_plugin Capistrano::Sidekiq::Systemd
```

### 2. Default Role Changed

The default role changed from `:app` to `:worker`.

#### Before (v2.x):
```ruby
# Sidekiq tasks ran on :app role by default
server 'app1.example.com', roles: [:app]  # Sidekiq would run here
```

#### After (v3.x):
```ruby
# Sidekiq tasks now run on :worker role by default
server 'worker1.example.com', roles: [:worker]  # Sidekiq runs here

# Or override the default:
set :sidekiq_roles, :app  # Use old behavior
```

### 3. Task Names Changed

Some task names have changed or been removed:

- `sidekiq:monit:*` tasks are completely removed
- Use standard systemd tasks: `sidekiq:start`, `sidekiq:stop`, `sidekiq:restart`

## Migration Steps

### Step 1: Update Your Gemfile

```ruby
# Gemfile
gem 'capistrano-sidekiq', '~> 3.0'
```

### Step 2: Update Your Capfile

```ruby
# Capfile
require 'capistrano/sidekiq'
install_plugin Capistrano::Sidekiq
install_plugin Capistrano::Sidekiq::Systemd
```

### Step 3: Update Your Deploy Configuration

```ruby
# config/deploy.rb or config/deploy/production.rb

# If you were using :app role, explicitly set it:
set :sidekiq_roles, :app

# Or update your server definitions to use :worker role:
server 'worker1.example.com', roles: [:worker]
```

### Step 4: Install Systemd Services

Before your first deployment with v3.x:

```bash
# Install systemd service files on your servers
cap production sidekiq:install

# This replaces any monit configuration you had
```

### Step 5: Remove Monit Configuration

On your servers, remove old monit configuration files:

```bash
# On each server
sudo rm /etc/monit/conf.d/sidekiq_*
sudo monit reload
```

## Troubleshooting

### "Don't know how to build task 'sidekiq:start'"

Make sure you have both lines in your Capfile:
```ruby
require 'capistrano/sidekiq'
install_plugin Capistrano::Sidekiq::Systemd
```

### "undefined method `as'"

This is a known issue in v3.0.0. Make sure you're using the latest version which includes the fix.

### Sidekiq doesn't start after deployment

1. Check that systemd services are installed:
   ```bash
   cap production sidekiq:install
   ```

2. Check service status:
   ```bash
   systemctl --user status sidekiq_myapp_production
   ```

3. Ensure your servers have the `:worker` role or you've set `:sidekiq_roles` appropriately.

## Getting Help

If you encounter issues during migration:

1. Check the [GitHub issues](https://github.com/seuros/capistrano-sidekiq/issues)
2. Review the [README](README.md) for current configuration options
3. Open a new issue with your specific migration problem