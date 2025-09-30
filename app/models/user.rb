# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  admin               :boolean
#  email               :string
#  google_uid          :string
#  name                :string
#  profile_picture_url :string
#  reference           :text
#  token               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  place_id            :bigint
#
# Indexes
#
#  index_users_on_place_id  (place_id)
#
class User < ApplicationRecord
  belongs_to :place, optional: true
  has_many :climbs

  def self.me(session)
    return nil unless session[:userinfo]

    find_by(id: session[:userinfo]['id'], token: session[:userinfo]['token'])
  end
end
