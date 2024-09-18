class AddGoogleUidToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :google_uid, :string
  end
end