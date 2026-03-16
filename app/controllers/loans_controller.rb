class LoansController < ApplicationController
  before_action :set_loan, only: [ :approve, :return_loan ]

  def index
    authorize Loan
    if current_user.admin?
      search_result = search_service.search_loans(
        user_id:      params[:user_id],
        equipment_id: params[:equipment_id],
        status:       params[:status],
        date_from:    params[:date_from],
        date_to:      params[:date_to],
        page:         params[:page]
      )
      @loans      = search_result.records
      @pagination = search_result
      @users_for_filter      = User.order(:email)
      @equipments_for_filter = Equipment.kept.order(:name)
    else
      @loans      = current_user.loans.includes(:equipment).order(created_at: :desc)
      @pagination = nil
    end
  end

  def new
    authorize Loan
    @loan = Loan.new
    @equipments = Equipment.kept.where(status: %w[available in_use repair]).order(:name)
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
      @equipments = Equipment.kept.where(status: %w[available in_use repair]).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def export_csv
    authorize Loan, :export_csv?
    loans = if current_user.admin?
      scope = Loan.includes(:equipment, :user).order(created_at: :desc)
      scope = scope.where(user_id: params[:user_id])           if params[:user_id].present?
      scope = scope.where(equipment_id: params[:equipment_id]) if params[:equipment_id].present?
      scope = scope.where(status: params[:status])             if params[:status].present?
      scope = scope.where("start_date >= ?", params[:date_from])           if params[:date_from].present?
      scope = scope.where("expected_return_date <= ?", params[:date_to])   if params[:date_to].present?
      scope
    else
      current_user.loans.includes(:equipment, :user).order(created_at: :desc)
    end
    csv = CsvExportService.new.export_loans(loans)
    send_data csv,
              filename: "loans_#{Date.today.strftime('%Y%m%d')}.csv",
              type: "text/csv; charset=utf-8"
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

  def search_service
    @search_service ||= SearchService.new
  end

  def loan_params
    params.require(:loan).permit(:equipment_id, :start_date, :expected_return_date)
  end
end
