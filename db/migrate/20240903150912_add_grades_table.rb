class AddGradesTable < ActiveRecord::Migration[7.1]
  def change
    create_table :grades do |t|
      t.references :place, null: false, foreign_key: true
      t.string :name
      t.string :grade
      t.string :map_tint_colour

      t.timestamps
    end
  end
end