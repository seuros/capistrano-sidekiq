# frozen_string_literal: true

server 'localhost', user: 'deploy', roles: %w[app web worker], port: 8022,
                    ssh_options: {
                      password: 'password',
                      auth_methods: %w[password],
                      user_known_hosts_file: '/dev/null'
                    }
