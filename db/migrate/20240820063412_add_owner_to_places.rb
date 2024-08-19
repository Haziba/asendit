class AddOwnerToPlaces < ActiveRecord::Migration[7.1]
  def change
    add_reference :places, :user, index: true
  end
end