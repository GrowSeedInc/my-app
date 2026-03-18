class Loan < ApplicationRecord
  RETURNABLE_STATUSES = %w[active overdue].freeze

  belongs_to :equipment
  belongs_to :user

  enum :status, {
    pending_approval: "pending_approval",
    active: "active",
    returned: "returned",
    overdue: "overdue"
  }

  scope :active_or_overdue, -> { where(status: %i[active overdue]) }
  scope :pending,           -> { where(status: :pending_approval) }
  scope :by_equipment,      ->(equipment_id) { where(equipment_id: equipment_id) }
  scope :by_user,           ->(user_id) { where(user_id: user_id) }

  validates :start_date, presence: true
  validates :expected_return_date, presence: true
  validate :expected_return_date_after_start_date

  private

  def expected_return_date_after_start_date
    return unless start_date.present? && expected_return_date.present?

    if expected_return_date <= start_date
      errors.add(:expected_return_date, "は開始日より後の日付を入力してください")
    end
  end
end
