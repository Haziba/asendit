class AddColourIdToRouteSet < ActiveRecord::Migration[7.1]
  def change
    add_reference :route_sets, :route_set_colour_set_colour, foreign_key: true
  end
end