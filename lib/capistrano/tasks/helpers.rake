# frozen_string_literal: true

namespace :sidekiq do
  namespace :helpers do
    desc 'Generate multiple Sidekiq config files'
    task :generate_configs, :count do |_task, args|
      count = (args[:count] || 3).to_i
      
      puts "Generating #{count} Sidekiq config files..."
      
      # Base template
      base_config = {
        concurrency: 10,
        timeout: 25,
        verbose: false,
        strict: true
      }
      
      # Generate config files
      count.times do |i|
        config = base_config.dup
        
        # Assign queues based on index
        config[:queues] = case i
                          when 0
                            [['critical', 2], ['high', 1]]
                          when 1
                            [['default', 1], ['medium', 1]]
                          else
                            [['low', 1], ['background', 1]]
                          end
        
        filename = i.zero? ? 'sidekiq.yml' : "sidekiq_#{i}.yml"
        filepath = "config/#{filename}"
        
        # Generate YAML content
        content = <<~YAML
          # Sidekiq configuration file #{i + 1}/#{count}
          :concurrency: #{config[:concurrency]}
          :timeout: #{config[:timeout]}
          :verbose: #{config[:verbose]}
          :strict: #{config[:strict]}
          
          :queues:
        YAML
        
        config[:queues].each do |queue, priority|
          content += "  - [#{queue}, #{priority}]\n"
        end
        
        puts "  Creating #{filepath}..."
        File.write(filepath, content)
      end
      
      puts "\nAdd to your deploy.rb:"
      puts "set :sidekiq_config_files, #{count.times.map { |i| i.zero? ? "'sidekiq.yml'" : "'sidekiq_#{i}.yml'" }.join(', ')}"
    end
    
    desc 'Show current Sidekiq configuration'
    task :show_config do
      on roles(fetch(:sidekiq_roles)) do
        within current_path do
          config_files = fetch(:sidekiq_config_files, ['sidekiq.yml'])
          
          config_files.each do |config_file|
            puts "\n=== #{config_file} ==="
            if test("[ -f config/#{config_file} ]")
              puts capture(:cat, "config/#{config_file}")
            else
              puts "  File not found"
            end
          end
        end
      end
    end
  end
end