class AddDeletedFlags < ActiveRecord::Migration[7.1]
  def change
    add_column :route_set_colour_set_colours, :deleted, :boolean, default: false
    add_column :route_set_colour_sets, :deleted, :boolean, default: false
  end
end