FactoryBot.define do
  factory :grade do
    name { Faker::Lorem.sentence }
    grade { Faker::Lorem.sentence }
    map_tint_colour { Faker::Lorem.sentence }

    place
  end

  factory :floorplan do
    name { "Test Floorplan" }
    data { [{id: 0, name: "Bottom Floor", image_id: 1}, {id: 1, name: "Top Floor", image_id: 2}] }
    place

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
    place
  end

  factory :route_set do
    added { Time.now }
    place
    grade
    created_at { Time.now }
    updated_at { Time.now }
  end

  factory :route do
    association :route_set
    pos_x { 1 }
    pos_y { 1 }
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
