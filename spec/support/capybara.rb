require 'capybara/rspec'

Capybara.configure do |config|
  config.default_driver = :selenium_chrome_headless
  config.app_host = 'http://localhost:3000'
  config.server_port = 3000
end
