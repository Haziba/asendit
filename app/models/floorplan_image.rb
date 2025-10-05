# == Schema Information
#
# Table name: floorplan_images
#
#  id           :bigint           not null, primary key
#  name         :string
#  order        :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  floorplan_id :bigint           not null
#
# Indexes
#
#  index_floorplan_images_on_floorplan_id  (floorplan_id)
#
# Foreign Keys
#
#  fk_rails_...  (floorplan_id => floorplans.id)
#
class FloorplanImage < ApplicationRecord
  belongs_to :floorplan

  has_one_attached :image

  validates :order, presence: true
end
