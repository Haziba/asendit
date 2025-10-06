class AddFloorplanIdToRouteSets < ActiveRecord::Migration[7.1]
  def change
    add_reference :route_sets, :floorplan, foreign_key: true, type: :bigint
  end
end
