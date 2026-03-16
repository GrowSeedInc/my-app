require "rails_helper"

RSpec.describe "Setups", type: :request do
  describe "GET /setup" do
    context "ユーザーが0件の場合" do
      it "200を返しセットアップフォームを表示する" do
        get setup_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "ユーザーが1件以上存在する場合" do
      before { create(:user) }

      it "ログイン画面へリダイレクトする" do
        get setup_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /setup" do
    context "ユーザーが0件の場合" do
      context "正常なパラメータの場合" do
        let(:valid_params) do
          {
            user: {
              name: "管理者",
              email: "admin@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end

        it "管理者ユーザーを作成する" do
          expect {
            post setup_path, params: valid_params
          }.to change(User, :count).by(1)
        end

        it "作成したユーザーのロールがadminである" do
          post setup_path, params: valid_params
          expect(User.last.admin?).to be true
        end

        it "セッションを確立してrootパスへリダイレクトする" do
          post setup_path, params: valid_params
          expect(response).to redirect_to(root_path)
        end
      end

      context "バリデーションエラーの場合" do
        let(:invalid_params) do
          {
            user: {
              name: "",
              email: "invalid",
              password: "short",
              password_confirmation: "mismatch"
            }
          }
        end

        it "ユーザーを作成しない" do
          expect {
            post setup_path, params: invalid_params
          }.not_to change(User, :count)
        end

        it "フォームを再表示する（422）" do
          post setup_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "ユーザーが1件以上存在する場合" do
      before { create(:user) }

      it "ログイン画面へリダイレクトする" do
        post setup_path, params: {
          user: {
            name: "管理者",
            email: "admin@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
