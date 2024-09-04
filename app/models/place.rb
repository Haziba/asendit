class Place < ApplicationRecord
  has_many :route_sets
  has_many :grades
  belongs_to :user
end