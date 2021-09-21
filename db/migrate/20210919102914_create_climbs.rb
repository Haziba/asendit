class CreateClimbs < ActiveRecord::Migration[6.1]
  def change
    create_table :climbs do |t|
      t.text :climber

      t.timestamps
    end
  end
end
