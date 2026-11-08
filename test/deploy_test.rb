# frozen_string_literal: true

require 'minitest/autorun'
require 'shellwords'

Minitest.after_run do
  DeployTest.container_id && system("docker stop #{DeployTest.container_id}")
end

class DeployTest < Minitest::Test
  class << self
    attr_accessor :container_id
  end

  def self.before_suite
    system 'docker build -t capistrano-sidekiq-test-server test'
    self.container_id = `docker run -d --privileged -p 8022:22 -p 6379:6379 -v #{Dir.pwd}:/src:ro capistrano-sidekiq-test-server`.strip
    sleep 5 # Give systemd time to start

    # Start Redis inside container
    system "docker exec #{container_id} systemctl start redis-server"
  end

  before_suite

  SERVICE = 'capistrano_sidekiq_test_sidekiq_production'
  CURRENT = '/var/www/capistrano_sidekiq_test/current'
  SIDEKIQ_LOG = '/var/www/capistrano_sidekiq_test/shared/log/sidekiq.log'

  # Run a shell command as the deploy user inside the test container.
  # The ruby image's BUNDLE_APP_CONFIG/GEM_HOME would override the release's
  # .bundle/config, so drop them to match what an SSH session sees.
  def remote(cmd)
    `docker exec -u deploy -e XDG_RUNTIME_DIR=/run/user/1000 #{self.class.container_id} \
      env -u BUNDLE_APP_CONFIG -u GEM_HOME -u BUNDLE_SILENCE_ROOT_WARNING bash -lc #{Shellwords.escape(cmd)}`
  end

  def service_state
    remote("systemctl --user is-active #{SERVICE}").strip
  end

  def wait_for(timeout: 20)
    deadline = Time.now + timeout
    until (result = yield)
      return false if Time.now > deadline

      sleep 1
    end
    result
  end

  def assert_service(state)
    assert wait_for { service_state == state }, "expected #{SERVICE} to be #{state}, got #{service_state}"
  end

  def test_deploy_and_sidekiq_operations
    Dir.chdir('test') do
      assert system('cap production sidekiq:install'), 'Failed to install sidekiq service'
      assert system('cap production deploy'), 'Failed to deploy application'
      assert_service 'active'

      # A job enqueued from the release is processed by the managed service
      remote("cd #{CURRENT} && bundle exec ruby -r ./app.rb -e 'TestJob.perform_async(%(cap-test))'")

      assert wait_for { remote("grep -c 'Processing job for cap-test' #{SIDEKIQ_LOG}").to_i.positive? },
             'Sidekiq did not process the enqueued job'

      assert system('cap production sidekiq:stop'), 'Failed to stop sidekiq'
      assert_service 'inactive'

      assert system('cap production sidekiq:start'), 'Failed to start sidekiq'
      assert_service 'active'

      assert system('cap production sidekiq:restart'), 'Failed to restart sidekiq'
      assert_service 'active'

      # Quiet stops fetching new jobs but keeps the process alive
      assert system('cap production sidekiq:quiet'), 'Failed to quiet sidekiq'
      assert_service 'active'
    end
  end

  def test_multiple_processes
    skip 'Multiple process test - implement after fixing systemd issues'
  end

  def test_rollback_hooks
    skip 'Rollback hook test - implement after basic functionality works'
  end
end
