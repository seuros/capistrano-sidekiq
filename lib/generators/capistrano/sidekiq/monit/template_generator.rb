require 'rails/generators/base'

module Capistrano
  module Sidekiq
    module Monit
      module Generators
        class TemplateGenerator < Rails::Generators::Base

          namespace "capistrano:sidekiq:monit:template"
          desc "Create local monitrc.erb, and erb files for monitored processes for customization"
          source_root File.expand_path('../templates', __FILE__)
          argument :templates_path, type: :string,
            default: "config/deploy/templates",
            banner: "path to templates"

          def copy_template
            copy_file "sidekiq_monit.conf.erb", "#{templates_path}/sidekiq_monit.erb"
          end

        end
      end
    end
  end
end
