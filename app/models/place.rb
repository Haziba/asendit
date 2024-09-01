class Place < ApplicationRecord
  has_many :colour_sets, class_name: 'RouteSetColourSet'
  belongs_to :user

  def active_colour_sets
    colour_sets.where(deleted: false)
  end
end