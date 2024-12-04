class Grade < ApplicationRecord
  belongs_to :place
  has_many :route_sets

  validates :name, presence: true
  validates :map_tint_colour, presence: true

  after_create_commit -> { broadcast_append_to place }
  after_update_commit -> { broadcast_replace_to place }
  after_destroy_commit -> { broadcast_remove_to place }

  def active_route_set
    route_sets.sort_by(&:added).last
  end

  def past_route_sets
    route_sets.order(added: :desc).offset(1)
  end
end