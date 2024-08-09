FactoryBot.define do
  factory :climb do
    climber { "Test Climber" }
    current { false }
    route_state_json { [] }
    climbed_at { Date.today }
    created_at { Time.now }
    updated_at { Time.now }
  end

  factory :route_set do
    color { "red" }
    added { Time.now }
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
end
