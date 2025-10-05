class AddStartsOnDateToRouteSets < ActiveRecord::Migration[7.1]
  def change
    add_column :route_sets, :starts_on, :date
  end
end
