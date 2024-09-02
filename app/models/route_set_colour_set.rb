class RouteSetColourSet < ApplicationRecord
  belongs_to :place
  has_many :colours, class_name: 'RouteSetColourSetColour'

  validates :description, presence: true
end
