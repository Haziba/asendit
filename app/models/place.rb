class Place < ApplicationRecord
  has_many :route_sets
  has_many :grades
  has_many :floorplans
  belongs_to :user
end