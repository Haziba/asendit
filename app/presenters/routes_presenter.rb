class RoutesPresenter
  attr_reader :routes, :user

  def initialize(routes, user = nil)
    @routes = routes
    @user = user
  end

  def present
    {
      routes: routes.map { |route| RoutePresenter.new(route, user).present }
    }
  end

  def present_summary
    {
      routes: routes.map { |route| RoutePresenter.new(route, user).present_summary }
    }
  end
end