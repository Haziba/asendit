# == Schema Information
#
# Table name: tournaments
#
#  id         :bigint           not null, primary key
#  ending     :date             not null
#  name       :text             not null
#  starting   :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  place_id   :bigint           not null
#
# Indexes
#
#  index_tournaments_on_place_id  (place_id)
#
# Foreign Keys
#
#  fk_rails_...  (place_id => places.id)
#
class Tournament < ApplicationRecord
  belongs_to :place
  has_many :tournament_routes, dependent: :destroy

  validates :name, presence: true
  validates :starting, presence: true
  validates :ending, presence: true
  validate :ending_after_starting

  private

  def ending_after_starting
    return unless starting && ending
    errors.add(:ending, 'must be after starting date') if ending < starting
  end
end
