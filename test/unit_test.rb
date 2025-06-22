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
    obj.instance_variable_set(:@config_file, "custom.yml")
    assert_equal "--config config/custom.yml", obj.sidekiq_config
    
    obj.instance_variable_set(:@config_file, "sidekiq.yml")
    assert_nil obj.sidekiq_config
  end

  def test_systemd_plugin
    systemd = Capistrano::Sidekiq::Systemd.new
    assert_instance_of Capistrano::Sidekiq::Systemd, systemd
  end

  def test_version_constant
    assert_match(/^\d+\.\d+\.\d+/, Capistrano::SidekiqVERSION)
  end
end

class SidekiqCommonTest < Minitest::Test
  include Capistrano::SidekiqCommon

  def fetch(key, default = nil)
    @config ||= {}
    @config[key] || default
  end

  def test_sidekiq_user_with_nil_role
    @config = { sidekiq_user: 'sidekiq' }
    assert_equal 'sidekiq', sidekiq_user(nil)
  end

  def test_sidekiq_user_with_role
    role = Struct.new(:user, :properties).new('deploy', {})
    @config = {}
    assert_equal 'deploy', sidekiq_user(role)
  end

  def test_sidekiq_user_with_role_property
    role = Struct.new(:user, :properties).new('deploy', { sidekiq_user: 'custom' })
    @config = {}
    assert_equal 'custom', sidekiq_user(role)
  end

  def test_sidekiq_config_default
    @config_file = 'sidekiq.yml'
    assert_nil sidekiq_config
  end

  def test_sidekiq_config_custom
    @config_file = 'custom.yml'
    assert_equal '--config config/custom.yml', sidekiq_config
  end
end