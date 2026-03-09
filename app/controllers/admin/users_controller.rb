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
