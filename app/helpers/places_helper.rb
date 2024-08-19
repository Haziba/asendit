module PlacesHelper
  def user_can_edit_place?(place)
    user = User.me(session)
    place.user == user || session['admin'] == true
  end
end