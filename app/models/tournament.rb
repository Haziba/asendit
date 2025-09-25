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
