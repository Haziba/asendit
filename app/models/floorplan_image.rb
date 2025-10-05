class FloorplanImage < ApplicationRecord
  belongs_to :floorplan

  has_one_attached :image

  validates :order, presence: true
end
