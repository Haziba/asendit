class CreateTournamentsRoutesJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :tournaments, :routes do |t|
      t.index :tournament_id
      t.index :route_id
    end
  end
end