class LoanService
  # @param user [User]
  # @param equipment_id [String]
  # @param start_date [Date]
  # @param expected_return_date [Date]
  # @return [Hash] { success: Boolean, loan: Loan, error: Symbol, message: String }
  def create(user:, equipment_id:, start_date:, expected_return_date:)
    equipment = Equipment.kept.find_by(id: equipment_id)

    unless equipment
      return { success: false, error: :equipment_not_available, message: "指定された備品は利用できません" }
    end

    unless equipment.available? || equipment.in_use?
      return { success: false, error: :equipment_not_available, message: "この備品は現在貸出対象外です（ステータス: #{equipment.status}）" }
    end

    loan = Loan.new(
      user: user,
      equipment: equipment,
      start_date: start_date,
      expected_return_date: expected_return_date,
      status: :pending_approval
    )

    unless loan.valid?
      return { success: false, loan: loan, error: :validation_failed, message: loan.errors.full_messages.join(", ") }
    end

    result = nil

    ActiveRecord::Base.transaction do
      equipment.with_lock do
        if equipment.available_count <= 0
          result = { success: false, error: :out_of_stock, message: "現在在庫がありません" }
          raise ActiveRecord::Rollback
        end

        loan.save!
        equipment.decrement!(:available_count)
        result = { success: true, loan: loan }
      end
    end

    result
  end

  # @param loan_id [String]
  # @return [Hash]
  def approve(loan_id:)
    loan = Loan.find(loan_id)

    unless loan.pending_approval?
      return { success: false, error: :invalid_status_transition, message: "承認待ち状態の貸出のみ承認できます" }
    end

    loan.update!(status: :active)
    { success: true, loan: loan }
  end

  # @param loan [Loan]
  # @return [void]
  def mark_overdue(loan:)
    loan.update!(status: :overdue)
  end
end
