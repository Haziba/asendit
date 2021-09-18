class CreateRoutes < ActiveRecord::Migration[6.1]
  def change
    create_table :routes do |t|
      t.belongs_to :route_set
      t.integer :pos_x
      t.integer :pos_y
      t.datetime :added
      t.integer :floor

      t.timestamps
    end
  end
end
