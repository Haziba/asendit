class RouteSetsPresenter
  attr_reader :route_sets, :user

  def initialize(route_sets, user = nil)
    @route_sets = route_sets
    @user = user
  end

  def present
    {
      route_sets: route_sets.map { |route_set| RouteSetPresenter.new(route_set, user).present }
    }
  end

  def present_grouped_by_status(active_route_sets, past_route_sets)
    {
      active_route_sets: active_route_sets.map { |rs| RouteSetPresenter.new(rs, user).present_summary },
      past_route_sets: past_route_sets.map { |rs| RouteSetPresenter.new(rs, user).present_summary }
    }
  end
end