class RouteSet < ApplicationRecord
  belongs_to :place
  belongs_to :route_set_colour_set_colour
  has_many :routes
  has_and_belongs_to_many :route_sets
  
  def name
    "#{route_set_colour_set_colour&.colour&.titleize || color.titleize} (#{added.to_date})"
  end
end
