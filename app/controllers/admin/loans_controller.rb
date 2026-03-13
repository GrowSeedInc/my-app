class Admin::LoansController < ApplicationController
  def new
    authorize Loan, :admin_entry?
    @loan = Loan.new
    load_form_data
  end

  def create
    authorize Loan, :admin_entry?

    target_user = User.find_by(id: loan_params[:user_id])
    unless target_user
      @loan = Loan.new(loan_params.except(:user_id, :mode))
      @loan.errors.add(:base, "対象ユーザーを選択してください")
      load_form_data
      render :new, status: :unprocessable_entity
      return
    end

    result = if loan_params[:mode] == "direct"
      loan_service.admin_direct_entry(
        user: target_user,
        equipment_id: loan_params[:equipment_id],
        start_date: loan_params[:start_date],
        expected_return_date: loan_params[:expected_return_date]
      )
    else
      loan_service.create(
        user: target_user,
        equipment_id: loan_params[:equipment_id],
        start_date: loan_params[:start_date],
        expected_return_date: loan_params[:expected_return_date]
      )
    end

    if result[:success]
      redirect_to loans_path, notice: "貸出を登録しました"
    else
      @loan = result[:loan] || Loan.new(loan_params.except(:user_id, :mode))
      @loan.errors.add(:base, result[:message]) unless result[:error] == :validation_failed
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_form_data
    @users = User.order(:name, :email)
    @equipments = Equipment.kept.where(status: %w[available in_use]).order(:name)
  end

  def loan_service
    @loan_service ||= LoanService.new
  end

  def loan_params
    params.require(:loan).permit(:user_id, :equipment_id, :start_date, :expected_return_date, :mode)
  end
end
