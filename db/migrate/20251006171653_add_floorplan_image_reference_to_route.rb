class AddFloorplanImageReferenceToRoute < ActiveRecord::Migration[7.1]
  def change
    add_reference :routes, :floorplan_image, foreign_key: true, type: :bigint, null: false
  end
end
