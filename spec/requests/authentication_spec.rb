require "rails_helper"

RSpec.describe "認証", type: :request do
  describe "未認証アクセス" do
    let!(:existing_user) { create(:user) }

    it "未認証ユーザーはログイン画面へリダイレクトされる" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "認証済みアクセス" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "認証済みユーザーはリダイレクトされない" do
      get root_path
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end
end
