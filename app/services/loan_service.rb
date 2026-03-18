class LoanService
  # @param user [User]
  # @param equipment_id [String]
  # @param start_date [Date]
  # @param expected_return_date [Date]
  # @return [ServiceResult]
  def create(user:, equipment_id:, start_date:, expected_return_date:)
    build_and_save_loan(
      user: user,
      equipment_id: equipment_id,
      start_date: start_date,
      expected_return_date: expected_return_date,
      status: :pending_approval
    )
  end

  # @param user [User] 貸出対象の利用者
  # @param equipment_id [String] UUID
  # @param start_date [Date]
  # @param expected_return_date [Date]
  # @return [ServiceResult]
  def admin_direct_entry(user:, equipment_id:, start_date:, expected_return_date:)
    build_and_save_loan(
      user: user,
      equipment_id: equipment_id,
      start_date: start_date,
      expected_return_date: expected_return_date,
      status: :active
    )
  end

  # @param loan_id [String]
  # @return [ServiceResult]
  def approve(loan_id:)
    loan = Loan.find(loan_id)

    unless loan.pending_approval?
      return ServiceResult.err(error: :invalid_status_transition, message: "承認待ち状態の貸出のみ承認できます", loan: loan)
    end

    loan.update!(status: :active)
    ServiceResult.ok(loan: loan)
  end

  # @param loan [Loan]
  # @return [void]
  def mark_overdue(loan:)
    loan.update!(status: :overdue)
  end

  private

  def build_and_save_loan(user:, equipment_id:, start_date:, expected_return_date:, status:)
    equipment = Equipment.kept.find_by(id: equipment_id)

    unless equipment
      return ServiceResult.err(error: :equipment_not_available, message: "指定された備品は利用できません")
    end

    unless equipment.available? || equipment.in_use?
      return ServiceResult.err(error: :equipment_not_available, message: "この備品は現在貸出対象外です（ステータス: #{equipment.status}）")
    end

    loan = Loan.new(
      user: user,
      equipment: equipment,
      start_date: start_date,
      expected_return_date: expected_return_date,
      status: status
    )

    unless loan.valid?
      return ServiceResult.err(error: :validation_failed, message: loan.errors.full_messages.join(", "), loan: loan)
    end

    result = nil

    ActiveRecord::Base.transaction do
      equipment.with_lock do
        if equipment.available_count <= 0
          result = ServiceResult.err(error: :out_of_stock, message: "現在在庫がありません")
          raise ActiveRecord::Rollback
        end

        loan.save!
        equipment.decrement!(:available_count)
        result = ServiceResult.ok(loan: loan)

        if equipment.low_stock_threshold > 0 && equipment.available_count < equipment.low_stock_threshold
          notification_service.send_low_stock_alert(equipment: equipment)
        end
      end
    end

    notification_service.send_loan_confirmation(loan: loan) if result.success?

    result
  end

  def notification_service
    @notification_service ||= NotificationService.new
  end
end
