class CreateRouteSetColourSetColours < ActiveRecord::Migration[7.1]
  def change
    create_table :route_set_colour_set_colours do |t|
      t.string :colour, null: false
      t.string :map_tint_colour

      t.references :route_set_colour_set_colour, null: false, foreign_key: true

      t.timestamps
    end
  end
end
