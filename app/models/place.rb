class Place < ApplicationRecord
  has_many :route_sets, dependent: :destroy
  has_many :tournaments, dependent: :destroy
  has_many :grades, dependent: :destroy
  has_many :climbs, dependent: :destroy
  has_one :floorplan, dependent: :destroy
  belongs_to :user

  validates :name, presence: true, length: { minimum: 4 }

  def can_edit?(user)
    self.user == user
  end
end