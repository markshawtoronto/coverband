# frozen_string_literal: true

require File.expand_path('../test_helper', File.dirname(__FILE__))
require File.expand_path('../fake_app/basic_rack', File.dirname(__FILE__))
require 'rack'

class MiddlewareTest < Test::Unit::TestCase
  BASE_KEY = Coverband::Adapters::RedisStore::BASE_KEY

  def setup
    Coverband.configure do |config|
      config.store = Coverband::Adapters::RedisStore.new(Redis.new)
    end
  end

  test 'call app' do
    request = Rack::MockRequest.env_for('/anything.json')
    Coverband::Collectors::Base.instance.reset_instance
    middleware = Coverband::Middleware.new(fake_app)
    results = middleware.call(request)
    assert_equal '/anything.json', results.last
  end

  test 'pass all rack lint checks' do
    Coverband::Collectors::Base.instance.reset_instance
    app = Rack::Lint.new(Coverband::Middleware.new(fake_app))
    env = Rack::MockRequest.env_for('/hello')
    app.call(env)
  end

  test 'never be report coverage with reporting_frequency of 0' do
    request = Rack::MockRequest.env_for('/anything.json')
    Coverband::Collectors::Base.instance.reset_instance
    collector = Coverband::Collectors::Base.instance
    collector.instance_variable_set('@reporting_frequency', 0.0)
    middleware = Coverband::Middleware.new(fake_app)
    store = Coverband::Collectors::Base.instance.instance_variable_get('@store')
    store.expects(:save_report).never
    middleware.call(request)
  end

  test 'always be enabled with sample percentage of 100' do
    request = Rack::MockRequest.env_for('/anything.json')
    Coverband::Collectors::Base.instance.reset_instance
    collector = Coverband::Collectors::Base.instance
    collector.instance_variable_set('@reporting_frequency', 100.0)
    middleware = Coverband::Middleware.new(fake_app)
    store = Coverband::Collectors::Base.instance.instance_variable_get('@store')
    store.expects(:save_report).once
    middleware.call(request)
  end

  test 'reports coverage when an error is raised' do
    request = Rack::MockRequest.env_for('/anything.json')
    Coverband::Collectors::Base.instance.reset_instance
    Coverband::Collectors::Base.instance.expects(:report_coverage).once
    middleware = Coverband::Middleware.new(fake_app_raise_error)
    begin
      middleware.call(request)
    rescue StandardError
      nil
    end
  end

  private

  def fake_app
    @fake_app ||= lambda do |env|
      [200, { 'Content-Type' => 'text/plain' }, env['PATH_INFO']]
    end
  end

  def fake_app_raise_error
    @fake_app_raise_error ||= -> { raise 'hell' }
  end
end
