class ReturnService
  # @param loan_id [String]
  # @param actor [User]
  # @return [ServiceResult]
  def process_return(loan_id:, actor:)
    loan = Loan.find(loan_id)

    unless Loan::RETURNABLE_STATUSES.include?(loan.status)
      return ServiceResult.err(
        error: :invalid_status,
        message: "貸出中または延滞中の貸出のみ返却処理できません",
        loan: loan
      )
    end

    ActiveRecord::Base.transaction do
      loan.update!(status: :returned, actual_return_date: Date.today)
      loan.equipment.increment!(:available_count)
    end

    ServiceResult.ok(loan: loan)
  end
end
