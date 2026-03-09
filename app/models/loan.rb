class Loan < ApplicationRecord
  belongs_to :equipment
  belongs_to :user

  enum :status, {
    pending_approval: "pending_approval",
    active: "active",
    returned: "returned",
    overdue: "overdue"
  }

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
