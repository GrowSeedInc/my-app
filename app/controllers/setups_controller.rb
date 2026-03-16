class SetupsController < ApplicationController
  skip_before_action :redirect_to_setup_if_no_users
  skip_before_action :authenticate_user!
  before_action :redirect_if_users_exist

  def new
    @user = User.new
  end

  def create
    @user = User.new(setup_params)
    @user.role = :admin

    if @user.save
      sign_in(@user)
      redirect_to root_path, notice: "管理者アカウントを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_users_exist
    redirect_to new_user_session_path if User.exists?
  end

  def setup_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
