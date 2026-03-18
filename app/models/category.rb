class Category < ApplicationRecord
  enum :level, { major: 0, medium: 1, minor: 2 }

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :restrict_with_error
  has_many :equipments, dependent: :restrict_with_error

  scope :major,  -> { where(level: :major) }
  scope :medium, -> { where(level: :medium) }
  scope :minor,  -> { where(level: :minor) }

  # 大分類 ID 配下の小分類 ID 一覧を返すサブクエリ
  scope :minors_under_major,  ->(major_id)  {
    minor.where(parent_id: medium.where(parent_id: major_id).select(:id)).select(:id)
  }
  # 中分類 ID 配下の小分類 ID 一覧を返すサブクエリ
  scope :minors_under_medium, ->(medium_id) {
    minor.where(parent_id: medium_id).select(:id)
  }

  validates :name, presence: true, uniqueness: { scope: :parent_id }
  validates :parent_id, presence: true, if: -> { medium? || minor? }
  validate :parent_level_consistency

  # 「大分類 > 中分類 > 小分類」形式のパス文字列を返す。
  # 小分類モデルに対して呼ぶことを前提とする（eager_load: category: { parent: :parent } が必要）。
  def hierarchy_path(separator = " > ")
    [ parent&.parent&.name, parent&.name, name ].compact.join(separator)
  end

  private

  def parent_level_consistency
    if major? && parent_id.present?
      errors.add(:parent_id, "大分類に親カテゴリは設定できません")
      return
    end

    return unless parent_id.present?

    if parent.nil?
      errors.add(:parent_id, "存在しない親カテゴリが指定されています")
      return
    end

    if medium? && !parent.major?
      errors.add(:parent_id, "中分類の親は大分類である必要があります")
    elsif minor? && !parent.medium?
      errors.add(:parent_id, "小分類の親は中分類である必要があります")
    end
  end
end
