class Admin::UsersController < ApplicationController
  include CsvImportable

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
    return if validate_csv_upload(params[:file], admin_users_path)

    result = CsvImportService.new.import_users(params[:file])
    handle_csv_import_result(
      result, admin_users_path,
      success_notice: result[:success] ? "#{result[:message]}（初期パスワード: password123 — ユーザーに変更を促してください）" : nil
    )
  rescue ArgumentError => e
    redirect_to admin_users_path, alert: e.message
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
