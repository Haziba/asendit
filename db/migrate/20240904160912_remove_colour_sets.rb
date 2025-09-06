class RemoveColourSets < ActiveRecord::Migration[7.1]
  def change
    remove_reference :route_sets, :route_set_colour_set_colour, foreign_key: true
    drop_table :route_set_colour_set_colours
    drop_table :route_set_colour_sets
  end
end