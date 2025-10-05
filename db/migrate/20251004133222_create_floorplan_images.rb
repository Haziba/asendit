class CreateFloorplanImages < ActiveRecord::Migration[7.1]
  def change
    create_table :floorplan_images do |t|
      t.references :floorplan, null: false, foreign_key: true
      t.string :name
      t.integer :order

      t.timestamps
    end
  end
end
