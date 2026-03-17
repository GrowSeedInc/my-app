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

  def import_template
    authorize Loan, :import_csv?
    require "csv"
    headers = %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日]
    csv = "\xEF\xBB\xBF" + CSV.generate(encoding: "UTF-8") { |c| c << headers }
    send_data csv,
              filename: "loans_template.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_csv
    authorize Loan, :import_csv?

    file = params[:file]
    unless file.present?
      return redirect_to loans_path, alert: "ファイルを選択してください"
    end
    if file.size > 5.megabytes
      return redirect_to loans_path, alert: "ファイルサイズは5MB以下にしてください"
    end
    unless CsvImportService.new.csv_file?(file)
      return redirect_to loans_path, alert: "CSVファイルを選択してください"
    end

    result = CsvImportService.new.import_loans(file)

    if result[:success]
      msg = result[:message]
      if result[:warnings].any?
        msg += "（警告: #{result[:warnings].size}件の在庫不整合 — 備品管理画面で確認してください）"
      end
      redirect_to loans_path, notice: msg
    else
      errors = result[:errors]
      flash[:import_errors] = errors.first(50)
      flash[:import_errors_truncated] = errors.size - 50 if errors.size > 50
      redirect_to loans_path, alert: result[:message]
    end
  rescue ArgumentError => e
    redirect_to loans_path, alert: e.message
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
