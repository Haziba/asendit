# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🧗 Seeding climbing gym data..."

# Create sample users
users = [
  {
    name: "Alex Johnson",
    email: "alex@example.com",
    google_uid: "google_123",
    admin: true
  },
  {
    name: "Sarah Chen",
    email: "sarah@example.com",
    google_uid: "google_456",
    admin: false
  },
  {
    name: "Mike Rodriguez",
    email: "mike@example.com",
    google_uid: "google_789",
    admin: false
  }
]

created_users = []
users.each do |user_attrs|
  user = User.find_or_create_by(email: user_attrs[:email]) do |u|
    u.name = user_attrs[:name]
    u.google_uid = user_attrs[:google_uid]
    u.admin = user_attrs[:admin]
    u.token = SecureRandom.hex(16)
  end
  created_users << user
  puts "✅ Created user: #{user.name}"
end

# Create sample climbing gyms (places) with UK coordinates
places_data = [
  {
    name: "The Castle Climbing Centre",
    latitude: 51.5333,
    longitude: -0.1099,
    user: created_users[0]
  },
  {
    name: "Harrowall Climbing Centre",
    latitude: 51.8522,
    longitude: -0.2002,
    user: created_users[1]
  },
  {
    name: "The Arch Climbing Wall",
    latitude: 51.4905,
    longitude: -0.0743,
    user: created_users[0]
  },
  {
    name: "Edinburgh International Climbing Arena",
    latitude: 55.9391,
    longitude: -3.2823,
    user: created_users[2]
  },
  {
    name: "The Climbing Works Sheffield",
    latitude: 53.3811,
    longitude: -1.4701,
    user: created_users[1]
  },
  {
    name: "Depot Manchester",
    latitude: 53.4808,
    longitude: -2.2426,
    user: created_users[0]
  },
  {
    name: "Awesome Walls Liverpool",
    latitude: 53.4084,
    longitude: -2.9916,
    user: created_users[2]
  },
  {
    name: "Boulder Brighton",
    latitude: 50.8225,
    longitude: -0.1372,
    user: created_users[1]
  },
  {
    name: "Flashpoint Bristol",
    latitude: 51.4545,
    longitude: -2.5879,
    user: created_users[0]
  },
  {
    name: "The Climbing Academy Glasgow",
    latitude: 55.8642,
    longitude: -4.2518,
    user: created_users[2]
  },
  {
    name: "Depot Nottingham",
    latitude: 52.9548,
    longitude: -1.1336,
    user: created_users[0]
  }
]

created_places = []
places_data.each do |place_attrs|
  place = Place.find_or_create_by(name: place_attrs[:name]) do |p|
    p.latitude = place_attrs[:latitude]
    p.longitude = place_attrs[:longitude]
    p.user = place_attrs[:user]
  end
  created_places << place
  puts "✅ Created climbing gym: #{place.name}"
end

# Create grades for each place
grade_types = [
  { name: "V0-V2", grade: "beginner", map_tint_colour: "#90EE90" },
  { name: "V3-V4", grade: "intermediate", map_tint_colour: "#FFD700" },
  { name: "V5-V6", grade: "advanced", map_tint_colour: "#FF8C00" },
  { name: "V7+", grade: "expert", map_tint_colour: "#FF4500" },
  { name: "5.6-5.8", grade: "easy_route", map_tint_colour: "#87CEEB" },
  { name: "5.9-5.10", grade: "moderate_route", map_tint_colour: "#4169E1" },
  { name: "5.11+", grade: "hard_route", map_tint_colour: "#8B008B" }
]

created_places.each do |place|
  grade_types.each do |grade_attrs|
    grade = Grade.find_or_create_by(place: place, name: grade_attrs[:name]) do |g|
      g.grade = grade_attrs[:grade]
      g.map_tint_colour = grade_attrs[:map_tint_colour]
    end
    puts "✅ Created grade #{grade.name} for #{place.name}"
  end
end

created_places.each do |place|
  [1, 2].each do |i|
    floorplan = place.floorplans.create(name: "Floorplan #{i}", data: [], images: [])
    floorplan.floorplan_images.create(order: 0, image: File.open(Rails.root.join('spec', 'fixtures', 'files', 'FloorLower.png')))
    floorplan.floorplan_images.create(order: 1, image: File.open(Rails.root.join('spec', 'fixtures', 'files', 'FloorUpper.png')))
  end
  puts "✅ Created floorplans for #{place.name}"
end

# Create route sets for each place
created_places.each do |place|
  place.grades.each do |grade|
    # Create 2-3 route sets per grade
    (2..3).to_a.sample.times do |i|
      route_set = RouteSet.find_or_create_by(
        place: place,
        grade: grade,
        floorplan: place.floorplans.sample,
        added: rand(30.days).seconds.ago
      ) do |rs|
        rs.expires_at = rand(30.days).seconds.from_now.to_date
      end

      # Create 8-15 routes per route set
      route_count = rand(8..15)
      route_count.times do |route_num|
        Route.find_or_create_by(
          route_set: route_set,
          pos_x: rand(50..800),
          pos_y: rand(50..600),
          floorplan_image: route_set.floorplan.images.sample
        ) do |r|
          r.added = route_set.added + rand(1.day).seconds
        end
      end

      puts "✅ Created route set for #{grade.name} at #{place.name} with #{route_set.routes.count} routes"
    end
  end
end

# Create some sample climbs
created_users.each do |user|
  # Each user climbs at 1-2 random places
  sample_places = created_places.sample(rand(1..2))

  sample_places.each do |place|
    climb = Climb.find_or_create_by(
      user: user,
      place: place,
      climbed_at: rand(7.days).seconds.ago.to_date
    ) do |c|
      c.climber = user.name
      c.current = [true, false].sample

      # Create random route states for some routes
      route_states = []
      place.route_sets.limit(3).each do |route_set|
        route_set.routes.sample(rand(2..5)).each do |route|
          route_states << {
            route_id: route.id,
            status: rand(0..3) # 0: not_attempted, 1: attempted, 2: completed, 3: flashed
          }
        end
      end
      c.route_state_json = route_states
    end
    puts "✅ Created climb session for #{user.name} at #{place.name}"
  end
end

puts "\n🎉 Seeding complete!"
puts "📊 Summary:"
puts "  Users: #{User.count}"
puts "  Places: #{Place.count}"
puts "  Grades: #{Grade.count}"
puts "  Route Sets: #{RouteSet.count}"
puts "  Routes: #{Route.count}"
puts "  Climbs: #{Climb.count}"
puts "\n🧗 You can now test the API with sample data!"
puts "Try: GET /api/v1/places"
puts "Or with location: GET /api/v1/places?lat=51.5074&lng=-0.1278"
puts "(That's London coordinates for finding nearby climbing gyms!)"
