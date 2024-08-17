class RouteSetColourSet < ApplicationRecord
  belongs_to :place
  has_many :route_set_colour_set_colours
end
