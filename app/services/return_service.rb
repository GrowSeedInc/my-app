class ReturnService
  RETURNABLE_STATUSES = %w[active overdue].freeze

  # @param loan_id [String]
  # @param actor [User]
  # @return [Hash] { success: Boolean, loan: Loan, error: Symbol, message: String }
  def process_return(loan_id:, actor:)
    loan = Loan.find(loan_id)

    unless RETURNABLE_STATUSES.include?(loan.status)
      return {
        success: false,
        loan: loan,
        error: :invalid_status,
        message: "貸出中または延滞中の貸出のみ返却処理できません"
      }
    end

    ActiveRecord::Base.transaction do
      loan.update!(status: :returned, actual_return_date: Date.today)
      loan.equipment.increment!(:available_count)
    end

    { success: true, loan: loan }
  end
end
