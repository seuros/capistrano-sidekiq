# frozen_string_literal: true

require 'sidekiq'

# Loaded by Sidekiq via `-r ./app.rb` (non-Rails apps must name their jobs file).
class TestJob
  include Sidekiq::Job

  def perform(name = 'test')
    puts "Processing job for #{name}"
  end
end
