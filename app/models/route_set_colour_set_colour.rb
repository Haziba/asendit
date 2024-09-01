class RouteSetColourSetColour < ApplicationRecord
  belongs_to :route_set_colour_set

  validates :colour, presence: true
  validates :map_tint_colour, presence: true
end
