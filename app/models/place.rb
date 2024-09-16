class Place < ApplicationRecord
  has_many :route_sets
  has_many :tournaments
  has_many :grades
  has_many :climbs
  has_one :floorplan
  belongs_to :user

  def can_edit?(user)
    self.user == user
  end
end