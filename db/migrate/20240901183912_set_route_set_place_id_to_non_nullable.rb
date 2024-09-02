class SetRouteSetPlaceIdToNonNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :route_sets, :place_id, false
  end
end