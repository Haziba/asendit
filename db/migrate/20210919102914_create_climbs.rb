class CreateClimbs < ActiveRecord::Migration[6.1]
  def change
    create_table :climbs do |t|
      t.text :climber
      t.jsonb :route_states

      t.timestamps
    end
  end
end
