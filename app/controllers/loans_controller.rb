class LoansController < ApplicationController
  before_action :set_loan, only: [ :approve, :return_loan ]

  def index
    authorize Loan
    @loans = policy_scope_loans
  end

  def new
    authorize Loan
    @loan = Loan.new
    @equipments = Equipment.kept.where(status: %w[available in_use]).order(:name)
  end

  def create
    authorize Loan
    result = loan_service.create(
      user: current_user,
      equipment_id: loan_params[:equipment_id],
      start_date: loan_params[:start_date],
      expected_return_date: loan_params[:expected_return_date]
    )

    if result[:success]
      redirect_to loans_path, notice: "貸出申請を受け付けました"
    else
      @loan = result[:loan] || Loan.new(loan_params)
      @loan.errors.add(:base, result[:message]) unless result[:error] == :validation_failed
      @equipments = Equipment.kept.where(status: %w[available in_use]).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    authorize @loan
    result = loan_service.approve(loan_id: @loan.id)

    if result[:success]
      redirect_to loans_path, notice: "貸出を承認しました"
    else
      redirect_to loans_path, alert: result[:message]
    end
  end

  def return_loan
    authorize @loan
    result = return_service.process_return(loan_id: @loan.id, actor: current_user)

    if result[:success]
      redirect_to loans_path, notice: "返却処理が完了しました"
    else
      redirect_to loans_path, alert: result[:message], status: :unprocessable_entity
    end
  end

  private

  def set_loan
    @loan = Loan.find(params[:id])
  end

  def loan_service
    @loan_service ||= LoanService.new
  end

  def return_service
    @return_service ||= ReturnService.new
  end

  def loan_params
    params.require(:loan).permit(:equipment_id, :start_date, :expected_return_date)
  end

  def policy_scope_loans
    if current_user.admin?
      Loan.includes(:equipment, :user).order(created_at: :desc)
    else
      current_user.loans.includes(:equipment).order(created_at: :desc)
    end
  end
end
