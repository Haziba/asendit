class Place < ApplicationRecord
  has_many :route_sets
  has_many :grades
  has_one :floorplan
  belongs_to :user
end