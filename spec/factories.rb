FactoryBot.define do
  factory :route_set_colour_set_colour do
    colour { Faker::Lorem.sentence }
    map_tint_colour { Faker::Lorem.sentence }
    association :route_set_colour_set
  end

  factory :route_set_colour_set do
    description { Faker::Lorem.sentence }
    active { true }
    place

    after(:create) do |route_set_colour_set|
      create_list(:route_set_colour_set_colour, 3, route_set_colour_set: route_set_colour_set)
    end
  end

  factory :place do
    name { "Test Gym" }
    user

    after(:create) do |place|
      create_list(:route_set_colour_set, 3, place: place)
    end
  end

  factory :climb do
    climber { "Test Climber" }
    current { false }
    route_state_json { [] }
    climbed_at { Date.today }
    created_at { Time.now }
    updated_at { Time.now }
  end

  factory :route_set do
    route_set_colour_set_colour
    added { Time.now }
    place
    created_at { Time.now }
    updated_at { Time.now }
  end

  factory :route do
    association :route_set
    pos_x { 1 }
    pos_y { 1 }
    floor { 1 }
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
    reference { 'test@test.com' }

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
      unless evaluator.without_place
        create(:place, user: user) unless Place.any?
        user.update(place: Place.first)
      end
    end
  end
end
