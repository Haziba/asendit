class RemoveColourFromRouteSet < ActiveRecord::Migration[7.1]
  def change
    remove_column :route_sets, :color
  end
end