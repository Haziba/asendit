class RouteState < ApplicationRecord
  enum status: [:not_attempted, :failed, :sent, :flashed]

  def success?
    ["sent", "flashed"].include? status
  end

  def tried?
    ["sent", "flashed", "failed"].include? status
  end
end
