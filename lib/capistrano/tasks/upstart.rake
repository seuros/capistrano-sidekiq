git_plugin = self

SUPPRESS_FAILURE = %w[|| echo NO_RUNNING_INSTANCE].freeze

namespace :sidekiq do
  desc 'Quiet sidekiq (stop fetching new tasks from Redis)'
  task :quiet do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        sudo :service, fetch(:sidekiq_service_unit_name), :reload, *SUPPRESS_FAILURE
      end
    end
  end

  desc 'Stop sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)'
  task :stop do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        sudo :service, fetch(:sidekiq_service_unit_name), :stop, *SUPPRESS_FAILURE
      end
    end
  end

  desc 'Start sidekiq'
  task :start do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        sudo :service, fetch(:sidekiq_service_unit_name), :start
      end
    end
  end

  desc 'Install upstart sidekiq service'
  task :install do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.create_upstart_template
      end
    end
  end

  desc 'UnInstall upstart sidekiq service'
  task :uninstall do
    on roles fetch(:sidekiq_roles) do |role|
      git_plugin.switch_user(role) do
        execute :rm, '-f', File.join(fetch(:service_unit_path, fetch_upstart_unit_path), fetch(:sidekiq_service_unit_name))
      end
    end
  end

  desc 'Generate service_locally'
  task :generate_service_locally do
    run_locally do
      File.write('sidekiq.conf', git_plugin.compiled_template)
    end
  end

  def fetch_upstart_unit_path
    if fetch(:sidekiq_service_unit_user) == :system
      # if the path is not standard `set :service_unit_path`
      "/etc/init"
    else
      home_dir = backend.capture :pwd
      File.join(home_dir, '.config', 'upstart')
    end
  end

  def compiled_template
    search_paths = [
      File.expand_path(
        File.join(*%w[.. .. .. generators capistrano sidekiq upstart templates sidekiq.conf.erb]),
        __FILE__
      ),
    ]
    template_path = search_paths.detect { |path| File.file?(path) }
    template = File.read(template_path)
    ERB.new(template).result(binding)
  end

  def create_upstart_template
    ctemplate = compiled_template
    upstart_path = fetch(:service_unit_path, fetch_upstart_unit_path)

    if fetch(:sidekiq_service_unit_user) != :system
      backend.execute :mkdir, "-p", upstart_path
    end
    conf_filename = "#{fetch :sidekiq_service_unit_name}.conf"
    backend.upload!(
      StringIO.new(ctemplate),
      "/tmp/#{conf_filename}"
    )
    if fetch(:sidekiq_service_unit_user) == :system
      backend.execute :sudo, :mv, "/tmp/#{conf_filename}", "#{upstart_path}/#{conf_filename}"
      backend.execute :sudo, :initctl,  'reload-configuration'
    else
      backend.execute :sudo, :mv, "/tmp/#{conf_filename}", "#{upstart_path}/#{conf_filename}"
      #backend.execute :sudo, :initctl,  'reload-configuration' #TODO
    end
  end

  def num_workers
    fetch(:sidekiq_upstart_num_workers, nil)
  end

end
