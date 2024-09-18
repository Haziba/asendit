FactoryBot.define do
  factory :tournament do
    name { Faker::Lorem.sentence }
    starting { Date.tomorrow }
    ending { Date.tomorrow + 7.days }

    before(:create) do |tournament|
      tournament.update(place: Place.first || create(:place))
      route_set = tournament.place.grades.first.active_route_set
      t_rs = route_set.routes.first(2).map { |route| create(:tournament_route, route: route, tournament: tournament) }
      tournament.update(tournament_routes: t_rs)
      t_rs.map(&:route).last.update(floor: 1)
    end
  end

  factory :tournament_route do
    tournament { association :tournament }
    route { association :route }

    before(:create) do |tournament_route|
      tournament_route.update(order: tournament_route.tournament.tournament_routes.count)
    end
  end

  factory :grade do
    name { Faker::Lorem.sentence }
    grade { Faker::Lorem.sentence }
    map_tint_colour { Faker::Lorem.sentence }
    place { association :place }
    route_sets { [] }

    after(:create) do |grade|
      grade.update(route_sets: [create(:route_set, place: grade.place, grade: grade, added: Date.today), create(:route_set, place: grade.place, grade: grade, added: Date.yesterday)]) unless grade.route_sets.any?
    end
  end

  factory :floorplan do
    name { "Test Floorplan" }
    data { [{id: 0, name: "Bottom Floor", image_id: 1}, {id: 1, name: "Top Floor", image_id: 2}] }
    place { association :place }

    after(:create) do |floorplan|
      floorplan.images.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'FloorLower.png')),
        filename: 'FloorLower.png',
        content_type: 'image/png'
      )
      floorplan.images.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'FloorUpper.png')),
        filename: 'FloorUpper.png',
        content_type: 'image/png'
      )
      floorplan.update(data: [{id: 0, name: "Bottom Floor", image_id: floorplan.images.first.id}, {id: 1, name: "Top Floor", image_id: floorplan.images.last.id}])
    end
  end

  factory :place do
    name { "Test Gym" }
    user { association :user }

    after(:create) do |place|
      create_list(:grade, 3, place: place)
      create(:floorplan, place: place)
    end
  end

  factory :climb do
    user { association :user }
    current { false }
    route_state_json { [] }
    route_sets { [] }
    climbed_at { Date.today }
    created_at { Time.now }
    updated_at { Time.now }
    place { association :place }
  end

  factory :route_set do
    added { Time.now }
    place { association :place }
    grade { association :grade }
    created_at { Time.now }
    updated_at { Time.now }

    after(:create) do |route_set|
      route_set.update(routes: 3.times.map { |_| create(:route, route_set: route_set) })
    end
  end

  factory :route do
    association :route_set
    pos_x { Faker::Number.between(from: 50, to: 200) }
    pos_y { Faker::Number.between(from: 50, to: 200) }
    floor { 0 }
    added { Time.now }
    created_at { Time.now }
    updated_at { Time.now }
  end

  factory :route_status do
    route_id { 1 }
    status { "sent" }

    initialize_with { new(route_id, status) }
  end

  factory :user do
    token { Faker::Lorem.sentence}

    transient do
      without_place { false }
    end

    trait :without_place do
      place { nil }

      transient do
        without_place { true }
      end
    end

    after(:create) do |user, evaluator|
      unless evaluator.without_place || user.place
        create(:place, user: user) unless Place.any?
        user.update(place: Place.first)
      end
    end
  end
end
