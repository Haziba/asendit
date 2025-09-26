# CORS configuration for React Native API access
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from any origin for development and React Native
    # In production, you should specify your React Native app's domain
    origins '*'

    # Only allow API endpoints
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: false
  end
end