class AddExpiryDateToRouteSets < ActiveRecord::Migration[6.1]
  def change
    add_column :route_sets, :expires_at, :date
  end
end
