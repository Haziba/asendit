require 'webmock/rspec'

# Allow connections to localhost and specific domains needed for testing
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    'googlechromelabs.github.io',  # Chrome driver version checks
    'storage.googleapis.com',  # Chrome driver downloads
    'chromedriver.storage.googleapis.com',  # Chrome driver downloads (legacy)
    'github.com',  # Potential driver downloads from GitHub
    'selenium-release.storage.googleapis.com'  # Selenium downloads
  ]
)