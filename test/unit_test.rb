# frozen_string_literal: true

require_relative 'test_helper'

class UnitTest < Minitest::Test
  def setup
    @plugin = Capistrano::Sidekiq.new
  end

  def test_plugin_defines_tasks
    # Verify the plugin can be instantiated
    assert_instance_of Capistrano::Sidekiq, @plugin
  end

  def test_sidekiq_common_module
    obj = Object.new
    obj.extend(Capistrano::SidekiqCommon)

    # Test sidekiq_config method
    obj.instance_variable_set(:@config_file, 'custom.yml')

    assert_equal '--config config/custom.yml', obj.sidekiq_config

    obj.instance_variable_set(:@config_file, 'sidekiq.yml')

    assert_nil obj.sidekiq_config
  end

  def test_systemd_plugin
    systemd = Capistrano::Sidekiq::Systemd.new

    assert_instance_of Capistrano::Sidekiq::Systemd, systemd
  end

  def test_version_constant
    assert_match(/^\d+\.\d+\.\d+/, Capistrano::SIDEKIQ_VERSION)
  end
end

class SidekiqCommonTest < Minitest::Test
  include Capistrano::SidekiqCommon

  # Like Capistrano's fetch, return a stored false instead of the default
  def fetch(key, default = nil)
    @config ||= {}
    @config.fetch(key, default)
  end

  # A real Capistrano server: its Properties#fetch takes a single argument,
  # unlike Hash#fetch, so a Hash stub would hide arity bugs.
  def server(user, **properties)
    Capistrano::Configuration::Server.new("#{user}@localhost").tap do |s|
      properties.each { |k, v| s.properties.set(k, v) }
    end
  end

  def test_sidekiq_user_with_nil_role
    @config = { sidekiq_user: 'sidekiq' }

    assert_equal 'sidekiq', sidekiq_user(nil)
  end

  def test_sidekiq_user_with_role
    role = server('deploy')
    @config = {}

    assert_equal 'deploy', sidekiq_user(role)
  end

  def test_sidekiq_user_with_role_property
    role = server('deploy', sidekiq_user: 'custom')
    @config = {}

    assert_equal 'custom', sidekiq_user(role)
  end

  def test_sidekiq_user_with_run_as_property
    role = server('deploy', run_as: 'shared')
    @config = {}

    assert_equal 'shared', sidekiq_user(role)
  end

  def test_sidekiq_config_default
    @config_file = 'sidekiq.yml'

    assert_nil sidekiq_config
  end

  def test_sidekiq_config_custom
    @config_file = 'custom.yml'

    assert_equal '--config config/custom.yml', sidekiq_config
  end

  # Echoes back what it is asked to capture, like `echo` on the server.
  FakeBackend = Struct.new(:commands) do
    def capture(*args)
      commands << args
      "#{args.drop(1).join(' ')}\n"
    end
  end

  def backend
    @backend ||= FakeBackend.new([])
  end

  def test_expanded_bundle_command_defaults_to_the_command_map
    @config = {}
    bundle = SSHKit.config.command_map[:bundle]

    assert_equal bundle, expanded_bundle_command
    assert_equal [[:echo, bundle]], backend.commands
  end

  def test_expanded_bundle_command_ignores_a_blank_setting
    @config = { sidekiq_service_unit_bundle_command: '  ' }

    assert_equal SSHKit.config.command_map[:bundle], expanded_bundle_command
  end

  def test_expanded_bundle_command_ignores_a_false_setting
    @config = { sidekiq_service_unit_bundle_command: false }

    assert_equal SSHKit.config.command_map[:bundle], expanded_bundle_command
  end

  def test_expanded_bundle_command_accepts_an_array_setting
    @config = { sidekiq_service_unit_bundle_command: %w[bin/bundle] }

    assert_equal 'bin/bundle', expanded_bundle_command
  end

  def test_expanded_bundle_command_uses_the_service_unit_setting
    @config = { sidekiq_service_unit_bundle_command: '~/.rvm/bin/rvm in /var/www/app/current do bundle' }

    assert_equal '~/.rvm/bin/rvm in /var/www/app/current do bundle', expanded_bundle_command
  end
end

class SidekiqSystemdDefaultsTest < Minitest::Test
  def teardown
    Capistrano.configuration.set(:service_unit_bundle_command, nil)
  end

  def test_service_unit_bundle_command_falls_back_to_the_shared_setting
    systemd = Capistrano::Sidekiq::Systemd.new
    systemd.set(:service_unit_bundle_command, 'bin/bundle')
    systemd.set_defaults

    assert_equal 'bin/bundle', systemd.fetch(:sidekiq_service_unit_bundle_command)
  end
end
