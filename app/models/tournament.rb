class Tournament < ApplicationRecord
  belongs_to :place
  has_many :tournament_routes
end
