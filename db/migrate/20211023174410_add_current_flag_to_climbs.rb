class AddCurrentFlagToClimbs < ActiveRecord::Migration[6.1]
  def change
    add_column :climbs, :current, :boolean
  end
end
