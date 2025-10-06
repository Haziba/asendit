# == Schema Information
#
# Table name: routes
#
#  id                 :bigint           not null, primary key
#  added              :datetime
#  pos_x              :integer
#  pos_y              :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  floorplan_image_id :bigint           not null
#  route_set_id       :bigint
#
# Indexes
#
#  index_routes_on_floorplan_image_id  (floorplan_image_id)
#  index_routes_on_route_set_id        (route_set_id)
#
# Foreign Keys
#
#  fk_rails_...  (floorplan_image_id => floorplan_images.id)
#
class Route < ApplicationRecord
  belongs_to :route_set
  belongs_to :floorplan_image

  validates :pos_x, presence: true, numericality: true
  validates :pos_y, presence: true, numericality: true
  validates :added, presence: true
end
