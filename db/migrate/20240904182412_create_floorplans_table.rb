class CreateFloorplansTable < ActiveRecord::Migration[7.1]
  def change
    create_table :floorplans do |t|
      t.references :place, null: false, foreign_key: true
      t.text :name, null: false
      t.jsonb :data, null: false, default: {}

      t.timestamps
    end
  end
end