class CreateRoutes < ActiveRecord::Migration[6.1]
  def change
    create_table :routes do |t|
      t.text :color
      t.integer :pos_x
      t.integer :pos_y
      t.integer :id
      t.datetime :added
      t.integer :floor

      t.timestamps
    end
  end
end
