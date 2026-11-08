# frozen_string_literal: true

require 'sinatra'
require 'sidekiq/web'
require_relative 'app'

get '/' do
  'Hello, Sidekiq'
end

get '/test' do
  TestJob.perform_async('capistrano-sidekiq-test')
  'Job enqueued'
end

run Rack::URLMap.new('/' => Sinatra::Application, '/sidekiq' => Sidekiq::Web)
