class RemoveColourSets < ActiveRecord::Migration[7.1]
  def change
    drop_table :route_set_colour_set_colours
    drop_table :route_set_colour_sets
  end
end