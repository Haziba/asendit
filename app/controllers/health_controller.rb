class HealthController < ApplicationController
  skip_before_action :login_if_in_dev
  skip_before_action :set_user
  skip_before_action :verify_authenticity_token

  def index
    # Check database connection
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      db_status = 'ok'
      db_error = nil
    rescue => e
      db_status = 'error'
      db_error = e.message
      Rails.logger.error "Health check database error: #{e.message}"
    end

    # Basic health check response
    health_data = {
      status: 'ok', # Always return OK for app health, even if DB is down
      app: 'running',
      database: db_status,
      timestamp: Time.current.iso8601,
      version: 'unknown'
    }

    # Add error details if database is down but don't fail health check
    health_data[:database_error] = db_error if db_error

    render json: health_data, status: :ok
  end
end