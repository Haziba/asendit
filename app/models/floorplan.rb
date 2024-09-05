class Floorplan < ApplicationRecord
  has_many_attached :images
  belongs_to :place
end