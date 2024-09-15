namespace :routes do
  desc "Set all routes' floor to zero"
  task set_floor_to_zero: :environment do
    Route.update_all(floor: 0)
    puts "All routes' floor set to zero."
  end
end