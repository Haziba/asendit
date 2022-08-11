class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.text :reference
      t.references :place

      t.timestamps
    end
  end
end
