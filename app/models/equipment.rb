class Equipment < ApplicationRecord
  self.table_name = "equipments"

  include Discard::Model
  self.discard_column = :discarded_at

  belongs_to :category, optional: true

  enum :status, {
    available: "available",
    in_use: "in_use",
    repair: "repair",
    disposed: "disposed"
  }

  validates :name, presence: true
  validates :management_number, presence: true, uniqueness: true
  validates :total_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :available_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
