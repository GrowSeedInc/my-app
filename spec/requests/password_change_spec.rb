require "rails_helper"

RSpec.describe "パスワード変更", type: :request do
  let(:user) { create(:user, password: "currentpassword", password_confirmation: "currentpassword") }

  before { sign_in user }

  describe "GET /users/edit" do
    it "パスワード変更画面が表示される" do
      get edit_user_registration_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /users" do
    context "有効なパラメータの場合" do
      it "パスワードを変更できる" do
        patch user_registration_path, params: {
          user: {
            password: "newpassword",
            password_confirmation: "newpassword",
            current_password: "currentpassword"
          }
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context "現在のパスワードが誤っている場合" do
      it "パスワードを変更できない" do
        patch user_registration_path, params: {
          user: {
            password: "newpassword",
            password_confirmation: "newpassword",
            current_password: "wrongpassword"
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "新パスワードが8文字未満の場合" do
      it "パスワードを変更できない" do
        patch user_registration_path, params: {
          user: {
            password: "short1",
            password_confirmation: "short1",
            current_password: "currentpassword"
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
