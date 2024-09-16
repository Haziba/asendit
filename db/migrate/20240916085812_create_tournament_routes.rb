class CreateTournamentRoutes < ActiveRecord::Migration[7.1]
  def change
    create_table :tournament_routes do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :route, null: false, foreign_key: true
      t.integer :order, null: false

      t.timestamps
    end
  end
end