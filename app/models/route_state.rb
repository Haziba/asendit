class RouteState < ApplicationRecord
  enum status: [:not_attempted, :failed, :sent]
end
