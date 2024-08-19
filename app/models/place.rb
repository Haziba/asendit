class Place < ApplicationRecord
  has_many :colour_sets, class_name: 'RouteSetColourSet'
  belongs_to :user
end