require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let!(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }

  describe "GET /admin/users" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get admin_users_path
        expect(response).to have_http_status(:ok)
      end

      it "ユーザー一覧が表示される" do
        target = create(:user, name: "表示ユーザー", email: "list@example.com")
        get admin_users_path
        expect(response.body).to include("list@example.com")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get admin_users_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/users/new" do
    before { sign_in admin }

    it "200を返す" do
      get new_admin_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/users" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      let(:valid_params) do
        { user: { name: "テストユーザー", email: "test@example.com", password: "password123", role: "member" } }
      end

      it "ユーザー一覧にリダイレクト" do
        post admin_users_path, params: valid_params
        expect(response).to redirect_to(admin_users_path)
      end

      it "ユーザーが作成される" do
        expect {
          post admin_users_path, params: valid_params
        }.to change(User, :count).by(1)
      end
    end

    context "無効なパラメータの場合" do
      it "422を返す" do
        post admin_users_path, params: { user: { name: "", email: "", password: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        post admin_users_path, params: { user: { name: "X", email: "x@x.com", password: "password123" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    let!(:target_user) { create(:user, name: "編集対象") }
    before { sign_in admin }

    it "200を返す" do
      get edit_admin_user_path(target_user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/users/:id" do
    let!(:target_user) { create(:user, name: "旧名前") }
    before { sign_in admin }

    context "有効なパラメータの場合" do
      it "ユーザー一覧にリダイレクト" do
        patch admin_user_path(target_user), params: { user: { name: "新名前" } }
        expect(response).to redirect_to(admin_users_path)
      end

      it "nameが更新される" do
        patch admin_user_path(target_user), params: { user: { name: "新名前" } }
        expect(target_user.reload.name).to eq("新名前")
      end

      it "roleをadminに変更できる" do
        patch admin_user_path(target_user), params: { user: { role: "admin" } }
        expect(target_user.reload.role).to eq("admin")
      end
    end

    context "無効なパラメータの場合（重複email）" do
      it "422を返す" do
        create(:user, email: "taken@example.com")
        patch admin_user_path(target_user), params: { user: { email: "taken@example.com" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/users/:id" do
    let!(:target_user) { create(:user, name: "削除対象") }
    before { sign_in admin }

    it "ユーザー一覧にリダイレクト" do
      delete admin_user_path(target_user)
      expect(response).to redirect_to(admin_users_path)
    end

    it "ユーザーが削除される" do
      expect {
        delete admin_user_path(target_user)
      }.to change(User, :count).by(-1)
    end

    context "アクティブな貸出があるユーザーの場合" do
      let!(:equipment) { create(:equipment) }
      let!(:loan) { create(:loan, user: target_user, equipment: equipment, status: :active) }

      it "削除に失敗してリダイレクト" do
        delete admin_user_path(target_user)
        expect(response).to redirect_to(admin_users_path)
        expect(User.find_by(id: target_user.id)).to be_present
      end
    end
  end
end
