class CreateRouteSetColourSets < ActiveRecord::Migration[7.1]
  def change
    create_table :route_set_colour_sets do |t|
      t.text :description, null: true
      t.boolean :active, default: false

      t.references :place, null: false, foreign_key: true

      t.timestamps
    end
  end
end
