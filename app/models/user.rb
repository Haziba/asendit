class User < ApplicationRecord
  belongs_to :place, optional: true
  has_many :climbs

  def self.me(session)
    return nil unless session[:userinfo]

    find_by(id: session[:userinfo]['id'], token: session[:userinfo]['token'])
  end
end
