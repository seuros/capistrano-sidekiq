module Capistrano
  module Sidekiq
    class Config
      attr_reader :processes
      def initialize(role)
        sidekiq_conf = role.properties.sidekiq
        @processes = Array(sidekiq_conf).collect do |conf|
          Capistrano::Sidekiq::Process.new(conf)
        end
      end
    end

    class Process
      attr_reader :name, :concurrency, :processes, :queues

      def initialize(configuration)
        @name = ['sidekiq',configuration[:name] ].compact.join('_')
        @concurrency = configuration.fetch(:concurrency, 25).to_i
        @processes = configuration.fetch(:processes, 1).to_i
        @queues = configuration.fetch(:queues, ['default'])
      end

      def to_yaml
        {
            concurrency: concurrency,
            queues: queues
        }.to_yaml
      end
    end

  end
end

namespace :sidekiq do
  desc 'upload sidekiq configurations to servers'
  task :upload_config do
    on roles(fetch(:sidekiq_role)) do |role|
      config = Capistrano::Sidekiq::Config.new(role)
      config.processes.each do |process|
        upload! StringIO.new(process.to_yaml), "#{fetch(:sidekiq_pids_path)}/#{process.name}"
      end
    end
  end
end
