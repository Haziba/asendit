class AddUserToClimbs < ActiveRecord::Migration[7.1]
  def change
    add_reference :climbs, :user, foreign_key: true
  end
end