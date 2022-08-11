class AddPlaceToRouteSets < ActiveRecord::Migration[6.1]
  def change
    add_reference :route_sets, :place, foreign_key: true
  end
end
