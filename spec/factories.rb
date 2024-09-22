FactoryBot.define do
  factory :tournament do
    transient do
      place { nil }
      with_routes { false }
    end

    trait :with_routes do
      with_routes { true } 
    end

    name { Faker::Lorem.sentence }
    starting { Date.tomorrow }
    ending { Date.tomorrow + 7.days }

    before(:create) do |tournament|
      grade = create(:grade, place: tournament.place)
      route_set = create(:route_set, :with_routes, place: grade.place, grade: grade)

      t_rs = route_set.routes.first(2).map { |route| create(:tournament_route, route: route, tournament: tournament) }
      tournament.update(tournament_routes: t_rs)
      t_rs.map(&:route).last.update(floor: 1)
    end

    after(:build) do |tournament, evaluator|
      tournament.place = evaluator.place || create(:place, tournaments: [tournament])
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
  end

  factory :floorplan do
    transient do
      place { nil }
    end

    name { "Test Floorplan" }
    data { [{id: 0, name: "Bottom Floor", image_id: 1}, {id: 1, name: "Top Floor", image_id: 2}] }

    after(:build) do |floorplan, evaluator|
      floorplan.place = evaluator.place || create(:place, floorplan: floorplan)
    end

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
    transient do
      with_grades { false }

      user { nil }
      floorplan { nil }
    end

    trait :with_grades do
      transient do
        with_grades { true }
      end
    end

    name { "Test Gym" }

    after(:build) do |place, evaluator|
      place.user = evaluator.user || create(:user, place: place)
      place.floorplan = evaluator.floorplan
    end

    after(:create) do |place, evaluator|
      place.user = create(:user, place: place) unless place.user
      place.floorplan = create(:floorplan, place: place) unless place.floorplan
      place.grades = create_list(:grade, 3, place: place) if evaluator.with_grades
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
    transient do
      with_routes { false }
    end

    trait :with_routes do
      transient do
        with_routes { true }
      end
    end

    added { Time.now }
    place { association :place }
    grade { association :grade }
    created_at { Time.now }
    updated_at { Time.now }

    after(:create) do |route_set, evaluator|
      route_set.routes = [create(:route, route_set: route_set, floor: 0), create(:route, route_set: route_set, floor: 1)] if evaluator.with_routes
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
