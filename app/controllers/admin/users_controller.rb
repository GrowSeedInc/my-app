class Admin::UsersController < ApplicationController
  before_action :set_user, only: [ :edit, :update, :destroy ]

  def index
    authorize User
    @users = User.order(:email)
  end

  def new
    authorize User
    @user = User.new
  end

  def create
    authorize User
    result = user_service.create(
      name:     user_params[:name],
      email:    user_params[:email],
      password: user_params[:password],
      role:     user_params[:role]
    )
    if result[:success]
      redirect_to admin_users_path, notice: "ユーザーを作成しました"
    else
      @user = result[:user]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    result = user_service.update(user: @user, params: user_update_params)
    if result[:success]
      redirect_to admin_users_path, notice: "ユーザー情報を更新しました"
    else
      @user = result[:user]
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    result = user_service.destroy(user: @user)
    if result[:success]
      redirect_to admin_users_path, notice: "ユーザーを削除しました"
    else
      redirect_to admin_users_path, alert: result[:message]
    end
  end

  def export_csv
    authorize User, :export_csv?
    csv = CsvExportService.new.export_users(User.order(:email))
    send_data csv,
              filename: "users_#{Date.today.strftime('%Y%m%d')}.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_template
    authorize User, :import_csv?
    require "csv"
    headers = %w[名前 メールアドレス ロール]
    csv = "\xEF\xBB\xBF" + CSV.generate(encoding: "UTF-8") { |c| c << headers }
    send_data csv,
              filename: "users_template.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_csv
    authorize User, :import_csv?

    file = params[:file]
    unless file.present?
      return redirect_to admin_users_path, alert: "ファイルを選択してください"
    end
    if file.size > 5.megabytes
      return redirect_to admin_users_path, alert: "ファイルサイズは5MB以下にしてください"
    end
    unless CsvImportService.new.csv_file?(file)
      return redirect_to admin_users_path, alert: "CSVファイルを選択してください"
    end

    result = CsvImportService.new.import_users(file)

    if result[:success]
      redirect_to admin_users_path,
                  notice: "#{result[:message]}（初期パスワード: password123 — ユーザーに変更を促してください）"
    else
      flash[:import_errors] = result[:errors]
      redirect_to admin_users_path, alert: result[:message]
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_service
    @user_service ||= UserService.new
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :role)
  end

  def user_update_params
    params.require(:user).permit(:name, :email, :role)
  end
end
