# frozen_string_literal: true

require 'minitest/autorun'
require 'net/http'
require 'json'

Minitest.after_run do
  DeployTest.container_id && system("docker stop #{DeployTest.container_id}")
end

class DeployTest < Minitest::Test
  class << self
    attr_accessor :container_id
  end

  def self.before_suite
    system 'docker build -t capistrano-sidekiq-test-server test'
    self.container_id = `docker run -d --privileged -p 8022:22 -p 3000:3000 -p 6379:6379 capistrano-sidekiq-test-server`.strip
    sleep 5 # Give systemd time to start

    # Start Redis inside container
    system "docker exec #{container_id} systemctl start redis-server"
  end

  before_suite

  def retry_get_response(uri, limit = 5)
    response = nil
    limit.times do
      response = Net::HTTP.get_response(URI.parse(uri))
    rescue Errno::ECONNRESET, EOFError, Errno::ECONNREFUSED
      sleep 1
    else
      break
    end
    response
  end

  def test_deploy_and_sidekiq_operations
    Dir.chdir('test') do
      # Install systemd service
      assert system('cap production sidekiq:install'), 'Failed to install sidekiq service'

      # Deploy the application
      assert system('cap production deploy'), 'Failed to deploy application'

      # Check if web app is running
      response = retry_get_response('http://localhost:3000')

      assert_equal '200', response.code
      assert_equal 'Hello, Sidekiq', response.body

      # Test sidekiq:stop
      assert system('cap production sidekiq:stop'), 'Failed to stop sidekiq'
      sleep 2

      # Test sidekiq:start
      assert system('cap production sidekiq:start'), 'Failed to start sidekiq'
      sleep 2

      # Enqueue a test job
      response = retry_get_response('http://localhost:3000/test')

      assert_equal '200', response.code
      assert_equal 'Job enqueued', response.body

      # Test sidekiq:restart
      assert system('cap production sidekiq:restart'), 'Failed to restart sidekiq'
      sleep 2

      # Test sidekiq:quiet
      assert system('cap production sidekiq:quiet'), 'Failed to quiet sidekiq'

      # Check Sidekiq web UI
      response = retry_get_response('http://localhost:3000/sidekiq')

      assert_equal '200', response.code
    end
  end

  def test_multiple_processes
    skip 'Multiple process test - implement after fixing systemd issues'
  end

  def test_rollback_hooks
    skip 'Rollback hook test - implement after basic functionality works'
  end
end
