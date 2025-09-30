# == Schema Information
#
# Table name: tournament_routes
#
#  id            :bigint           not null, primary key
#  order         :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  route_id      :bigint           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_tournament_routes_on_route_id       (route_id)
#  index_tournament_routes_on_tournament_id  (tournament_id)
#
# Foreign Keys
#
#  fk_rails_...  (route_id => routes.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
class TournamentRoute < ApplicationRecord
  belongs_to :tournament
  belongs_to :route
end
