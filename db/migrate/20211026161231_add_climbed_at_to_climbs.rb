class AddClimbedAtToClimbs < ActiveRecord::Migration[6.1]
  def change
    add_column :climbs, :climbed_at, :date
  end
end
