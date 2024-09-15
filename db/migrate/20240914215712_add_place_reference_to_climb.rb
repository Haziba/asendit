class AddPlaceReferenceToClimb < ActiveRecord::Migration[7.1]
  def change
    add_reference :climbs, :place
  end
end