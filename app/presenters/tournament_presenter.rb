class TournamentPresenter
  attr_reader :tournament, :user

  def initialize(tournament, user = nil)
    @tournament = tournament
    @user = user
  end

  def present_summary
    {
      id: tournament.id,
      name: tournament.name,
      starting: tournament.starting,
      ending: tournament.ending,
      route_count: tournament.tournament_routes.count,
      status: calculate_status,
      created_at: tournament.created_at,
      updated_at: tournament.updated_at
    }
  end

  def present_detail
    present_summary.merge(
      place: {
        id: tournament.place.id,
        name: tournament.place.name
      },
      can_edit: user&.admin || tournament.place.can_edit?(user)
    )
  end

  private

  def calculate_status
    today = Date.today
    if tournament.starting > today
      'upcoming'
    elsif tournament.ending < today
      'ended'
    else
      'active'
    end
  end
end