class Memo < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true

  scope :default_order, -> { order(:id) }
end
