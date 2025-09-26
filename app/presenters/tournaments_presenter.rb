class TournamentsPresenter
  attr_reader :tournaments, :user

  def initialize(tournaments, user = nil)
    @tournaments = tournaments
    @user = user
  end

  def present
    {
      tournaments: tournaments.map { |tournament| TournamentPresenter.new(tournament, user).present_summary }
    }
  end
end