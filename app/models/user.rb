class User < ApplicationRecord
  belongs_to :place, optional: true

  def self.me(session)
    return nil unless session[:userinfo]

    find_or_create_by(reference: session[:userinfo]['id'])
  end
end
