class AddAuth0FieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :email, :string
    add_column :users, :name, :string
    add_column :users, :profile_picture_url, :string
  end
end
