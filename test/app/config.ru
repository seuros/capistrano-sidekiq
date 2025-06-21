require 'sinatra'
require 'sidekiq'
require 'sidekiq/web'

# Simple worker for testing
class TestWorker
  include Sidekiq::Worker

  def perform(name = "test")
    puts "Processing job for #{name}"
  end
end

get '/' do
  'Hello, Sidekiq'
end

get '/test' do
  TestWorker.perform_async('capistrano-sidekiq-test')
  'Job enqueued'
end

run Rack::URLMap.new('/' => Sinatra::Application, '/sidekiq' => Sidekiq::Web)