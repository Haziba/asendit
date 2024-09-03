class AddRouteSetsReferenceToClimbs < ActiveRecord::Migration[7.1]
  def change
    create_table :climbs_route_sets do |t|
      t.references :climb, null: false, foreign_key: true
      t.references :route_set, null: false, foreign_key: true

      t.timestamps
    end

    add_index :climbs_route_sets, [:climb_id, :route_set_id], unique: true
  end
end