class Category < ApplicationRecord
  enum :level, { major: 0, medium: 1, minor: 2 }

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :restrict_with_error
  has_many :equipments, dependent: :restrict_with_error

  scope :major, -> { where(level: :major) }
  scope :medium, -> { where(level: :medium) }
  scope :minor, -> { where(level: :minor) }

  validates :name, presence: true, uniqueness: { scope: :parent_id }
  validates :parent_id, presence: true, if: -> { medium? || minor? }
  validate :parent_level_consistency

  private

  def parent_level_consistency
    return unless parent_id.present? && parent.present?

    if medium? && !parent.major?
      errors.add(:parent_id, "中分類の親は大分類である必要があります")
    elsif minor? && !parent.medium?
      errors.add(:parent_id, "小分類の親は中分類である必要があります")
    end
  end
end
