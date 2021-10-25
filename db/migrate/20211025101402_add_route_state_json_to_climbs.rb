class AddRouteStateJsonToClimbs < ActiveRecord::Migration[6.1]
  def change
    add_column :climbs, :route_state_json, :json, default: []
  end
end
