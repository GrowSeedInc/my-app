require "rails_helper"

RSpec.describe "Admin::Categories", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:member)   { create(:user) }
  let!(:category) { create(:category, name: "テストカテゴリ") }

  # ─── GET /admin/categories ───────────────────────────────────────────────
  describe "GET /admin/categories" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get admin_categories_path
        expect(response).to have_http_status(:ok)
      end

      it "カテゴリ名が表示される" do
        get admin_categories_path
        expect(response.body).to include("テストカテゴリ")
      end

      it "キーワード検索が動作する" do
        create(:category, name: "別カテゴリ")
        get admin_categories_path, params: { keyword: "テスト" }
        expect(response.body).to include("テストカテゴリ")
        expect(response.body).not_to include("別カテゴリ")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get admin_categories_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get admin_categories_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── GET /admin/categories/new ───────────────────────────────────────────
  describe "GET /admin/categories/new" do
    before { sign_in admin }

    it "200を返す" do
      get new_admin_category_path
      expect(response).to have_http_status(:ok)
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get new_admin_category_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      before { sign_out admin }

      it "ログイン画面にリダイレクト" do
        get new_admin_category_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── POST /admin/categories ───────────────────────────────────────────────
  describe "POST /admin/categories" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      let(:valid_params) { { category: { name: "新カテゴリ" } } }

      it "カテゴリ一覧にリダイレクト" do
        post admin_categories_path, params: valid_params
        expect(response).to redirect_to(admin_categories_path)
      end

      it "カテゴリが作成される" do
        expect {
          post admin_categories_path, params: valid_params
        }.to change(Category, :count).by(1)
      end

      it "成功フラッシュが設定される" do
        post admin_categories_path, params: valid_params
        expect(flash[:notice]).to eq("カテゴリを作成しました")
      end
    end

    context "無効なパラメータの場合（名前空欄）" do
      it "422を返す" do
        post admin_categories_path, params: { category: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "無効なパラメータの場合（名前重複）" do
      it "422を返す" do
        post admin_categories_path, params: { category: { name: "テストカテゴリ" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        post admin_categories_path, params: { category: { name: "新カテゴリ" } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      before { sign_out admin }

      it "ログイン画面にリダイレクト" do
        post admin_categories_path, params: { category: { name: "新カテゴリ" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── GET /admin/categories/:id/edit ──────────────────────────────────────
  describe "GET /admin/categories/:id/edit" do
    before { sign_in admin }

    it "200を返す" do
      get edit_admin_category_path(category)
      expect(response).to have_http_status(:ok)
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get edit_admin_category_path(category)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      before { sign_out admin }

      it "ログイン画面にリダイレクト" do
        get edit_admin_category_path(category)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── PATCH /admin/categories/:id ─────────────────────────────────────────
  describe "PATCH /admin/categories/:id" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      it "カテゴリ一覧にリダイレクト" do
        patch admin_category_path(category), params: { category: { name: "更新カテゴリ" } }
        expect(response).to redirect_to(admin_categories_path)
      end

      it "カテゴリ名が更新される" do
        patch admin_category_path(category), params: { category: { name: "更新カテゴリ" } }
        expect(category.reload.name).to eq("更新カテゴリ")
      end

      it "成功フラッシュが設定される" do
        patch admin_category_path(category), params: { category: { name: "更新カテゴリ" } }
        expect(flash[:notice]).to eq("カテゴリを更新しました")
      end
    end

    context "無効なパラメータの場合（名前空欄）" do
      it "422を返す" do
        patch admin_category_path(category), params: { category: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        patch admin_category_path(category), params: { category: { name: "更新カテゴリ" } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      before { sign_out admin }

      it "ログイン画面にリダイレクト" do
        patch admin_category_path(category), params: { category: { name: "更新カテゴリ" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── DELETE /admin/categories/:id ────────────────────────────────────────
  describe "DELETE /admin/categories/:id" do
    before { sign_in admin }

    context "備品が紐づいていないカテゴリの場合" do
      it "カテゴリ一覧にリダイレクト" do
        delete admin_category_path(category)
        expect(response).to redirect_to(admin_categories_path)
      end

      it "カテゴリが削除される" do
        expect {
          delete admin_category_path(category)
        }.to change(Category, :count).by(-1)
      end

      it "成功フラッシュが設定される" do
        delete admin_category_path(category)
        expect(flash[:notice]).to eq("カテゴリを削除しました")
      end
    end

    context "備品が紐づいているカテゴリの場合" do
      let!(:equipment) { create(:equipment, category: category) }

      it "カテゴリ一覧にリダイレクト" do
        delete admin_category_path(category)
        expect(response).to redirect_to(admin_categories_path)
      end

      it "カテゴリが削除されない" do
        expect {
          delete admin_category_path(category)
        }.not_to change(Category, :count)
      end

      it "エラーフラッシュが設定される" do
        delete admin_category_path(category)
        expect(flash[:alert]).to be_present
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        delete admin_category_path(category)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      before { sign_out admin }

      it "ログイン画面にリダイレクト" do
        delete admin_category_path(category)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── ナビゲーション ───────────────────────────────────────────────────────────
  describe "ナビゲーション" do
    it "管理者には「カテゴリ管理」リンクが表示される" do
      sign_in admin
      get admin_categories_path
      expect(response.body).to include("カテゴリ管理")
    end

    it "一般ユーザーには「カテゴリ管理」リンクが表示されない" do
      sign_in member
      get equipments_path
      expect(response.body).not_to include("カテゴリ管理")
    end
  end
end
