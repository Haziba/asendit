class CreateTournaments < ActiveRecord::Migration[7.1]
  def change
    create_table :tournaments do |t|
      t.references :place, null: false, foreign_key: true
      t.text :name, null: false
      t.date :starting, null: false
      t.date :ending, null: false
      
      t.timestamps
    end
  end
end