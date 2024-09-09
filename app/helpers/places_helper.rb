module PlacesHelper
  def user_can_edit_place?(place)
    user = User.me(session)
    place.user == user || session['admin'] == true
  end

  def current_place
    user = User.me(session)
    user.place
  end

  def is_current_place?(place)
    puts "Place: #{place.name}"
    puts "User: #{place == current_place}"
    place == current_place
  end
end