class Place < ApplicationRecord
  has_many :colour_sets, class_name: 'RouteSetColourSet'
  has_many :route_sets
  belongs_to :user

  def active_colour_sets
    colour_sets.where(deleted: false)
  end

  def active_colour_set
    colour_sets.find_by(active: true)
  end
end