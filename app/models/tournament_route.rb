class TournamentRoute < ApplicationRecord
  belongs_to :tournament
  has_one :route
end