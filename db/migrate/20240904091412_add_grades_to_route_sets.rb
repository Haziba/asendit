class AddGradesToRouteSets < ActiveRecord::Migration[7.1]
  def change
    add_reference :route_sets, :grade, foreign_key: true
  end
end