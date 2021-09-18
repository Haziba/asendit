class CreateRouteSets < ActiveRecord::Migration[6.1]
  def change
    create_table :route_sets do |t|
      t.text :color
      t.datetime :added

      t.timestamps
    end
  end
end
