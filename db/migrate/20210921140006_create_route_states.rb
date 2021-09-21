class CreateRouteStates < ActiveRecord::Migration[6.1]
  def change
    create_table :route_states do |t|
      t.belongs_to :climb
      t.belongs_to :route
      t.column :status, :integer

      t.timestamps
    end
  end
end
