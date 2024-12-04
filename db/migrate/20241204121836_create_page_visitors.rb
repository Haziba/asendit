class CreatePageVisitors < ActiveRecord::Migration[7.1]
  def change
    create_table :page_visitors do |t|
      t.string :page_identifier
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
