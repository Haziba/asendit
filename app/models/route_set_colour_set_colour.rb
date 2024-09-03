class RouteSetColourSetColour < ApplicationRecord
  belongs_to :route_set_colour_set
  has_many :route_sets

  validates :colour, presence: true
  validates :map_tint_colour, presence: true

  def active_route_set
    route_sets.sort_by(&:added).last
  end
end
