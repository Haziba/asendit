class ChangePlacesCoordinatesToNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :places, :latitude, false
    change_column_null :places, :longitude, false
  end
end
