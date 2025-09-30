# == Schema Information
#
# Table name: floorplans
#
#  id         :bigint           not null, primary key
#  data       :jsonb            not null
#  name       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  place_id   :bigint           not null
#
# Indexes
#
#  index_floorplans_on_place_id  (place_id)
#
# Foreign Keys
#
#  fk_rails_...  (place_id => places.id)
#
class Floorplan < ApplicationRecord
  has_many_attached :images
  belongs_to :place
end
