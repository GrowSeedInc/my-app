class Equipment < ApplicationRecord
  self.table_name = "equipments"

  include Discard::Model
  self.discard_column = :discarded_at

  belongs_to :category, optional: true
  has_many :loans

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
  validate :category_must_be_minor

  private

  def category_must_be_minor
    return if category_id.nil?
    return if category&.minor?

    errors.add(:category_id, "小分類（最下位カテゴリ）を選択してください")
  end
end
