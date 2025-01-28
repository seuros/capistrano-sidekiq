# Understanding Systemd Lingering in Capistrano Sidekiq

## What is Lingering?

Lingering is a systemd feature that allows user services to run without an active user session. When lingering is enabled for a user:

- Their user services can start at boot
- Their user services continue running after they log out
- Their user services can be managed independently of user sessions

## Why is Lingering Important for Sidekiq?

When running Sidekiq as a user service (`:service_unit_user = :user`), lingering becomes important because:

1. Sidekiq needs to run continuously, even when no user is logged in
2. Sidekiq should start automatically after server reboots
3. Deployments should work regardless of active user sessions

## Configuration in Capistrano Sidekiq

```ruby
set :sidekiq_lingering_user, -> { fetch(:lingering_user, fetch(:user)) } #lingering_user is optional, if the deploy user is the same
set :service_unit_user, :user #set to :user to enable lingering
```

The plugin automatically enables lingering during the `sidekiq:enable` task when:
- User-mode systemd is being used (`systemctl_user` is true)
- A lingering user is specified

## How Lingering is Managed

### Enabling Lingering

```ruby
# This happens automatically during sidekiq:enable if conditions are met
execute :loginctl, "enable-linger", fetch(:sidekiq_lingering_user)
```

### Checking Lingering Status

You can manually check if lingering is enabled for a user:

```bash
# Check lingering status
loginctl show-user USERNAME | grep Linger

# List all users with lingering enabled
ls /var/lib/systemd/linger/
```

## Common Scenarios and Solutions

### Scenario 1: Running as Deploy User
```ruby
# config/deploy.rb
set :user, 'deploy'
set :service_unit_user, :user
# Lingering will be enabled for 'deploy' user
```

### Scenario 2: Custom Lingering User
```ruby
# config/deploy.rb
set :user, 'deploy'
set :lingering_user, 'sidekiq'
set :service_unit_user, :user
# Lingering will be enabled for 'sidekiq' user
```

### Scenario 3: System Service (No Lingering Needed)
```ruby
# config/deploy.rb
set :service_unit_user, :system
# Lingering is not relevant for system services
```

## Troubleshooting

1. **Service Stops After Deployment**
    - Check if lingering is enabled: `loginctl show-user USERNAME | grep Linger`
    - Verify systemd user mode is correctly configured
    - Ensure the lingering user has appropriate permissions

2. **Service Doesn't Start on Boot**
    - Confirm lingering is enabled
    - Check systemd user service is enabled: `systemctl --user is-enabled sidekiq`
    - Verify service configuration in `~/.config/systemd/user/`

3. **Permission Issues**
    - Ensure the lingering user has access to required directories
    - Check if the user can write to log files and working directory
    - Verify systemd user instance is properly initialized

## Best Practices

1. **User Selection**
    - Use a dedicated service user for running Sidekiq
    - Ensure the user has minimal required permissions
    - Consider security implications of lingering enabled

2. **Configuration**
    - Always explicitly set `:service_unit_user`
    - Document lingering configuration in your deployment setup
    - Use consistent users across related services

3. **Monitoring**
    - Regularly check lingering status
    - Monitor service status after system reboots
    - Set up alerts for unexpected service stops

## System Requirements

- Systemd version supporting user lingering (systemd >= 206)
- Proper system permissions to enable lingering
- Sufficient user permissions for service directories
