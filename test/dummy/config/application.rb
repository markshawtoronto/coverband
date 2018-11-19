require "rails"
require "action_controller/railtie"
require 'coverband'

module Dummy
  class Application < Rails::Application
    # Coverband needs to be setup before any of the initializers to capture usage of them
    Coverband.configure(File.open("#{Rails.root}/config/coverband.rb"))
    config.middleware.use Coverband::Middleware
    config.before_initialize do
      Coverband.start
    end
    config.eager_load = false
  end
end

