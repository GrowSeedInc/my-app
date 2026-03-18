require "rails_helper"

RSpec.describe "Admin::CategoryMajors", type: :request do
  let!(:admin)  { create(:user, :admin) }
  let(:member)  { create(:user) }
  let!(:major)  { create(:category, name: "大分類テスト") }

  # ─── GET /admin/category_majors ──────────────────────────────────────────
  describe "GET /admin/category_majors" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get admin_category_majors_path
        expect(response).to have_http_status(:ok)
      end

      it "大分類名が表示される" do
        get admin_category_majors_path
        expect(response.body).to include("大分類テスト")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get admin_category_majors_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get admin_category_majors_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── GET /admin/category_majors/new ──────────────────────────────────────
  describe "GET /admin/category_majors/new" do
    before { sign_in admin }

    it "200を返す" do
      get new_admin_category_major_path
      expect(response).to have_http_status(:ok)
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get new_admin_category_major_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── POST /admin/category_majors ─────────────────────────────────────────
  describe "POST /admin/category_majors" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      let(:valid_params) { { category: { name: "新大分類" } } }

      it "大分類一覧にリダイレクト" do
        post admin_category_majors_path, params: valid_params
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "大分類が作成される" do
        expect {
          post admin_category_majors_path, params: valid_params
        }.to change(Category.major, :count).by(1)
      end

      it "成功フラッシュが設定される" do
        post admin_category_majors_path, params: valid_params
        expect(flash[:notice]).to eq("大分類を作成しました")
      end
    end

    context "無効なパラメータの場合（名前空欄）" do
      it "422を返す" do
        post admin_category_majors_path, params: { category: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "無効なパラメータの場合（名前重複）" do
      it "422を返す" do
        post admin_category_majors_path, params: { category: { name: "大分類テスト" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        post admin_category_majors_path, params: { category: { name: "新大分類" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── GET /admin/category_majors/:id/edit ─────────────────────────────────
  describe "GET /admin/category_majors/:id/edit" do
    before { sign_in admin }

    it "200を返す" do
      get edit_admin_category_major_path(major)
      expect(response).to have_http_status(:ok)
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get edit_admin_category_major_path(major)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── PATCH /admin/category_majors/:id ────────────────────────────────────
  describe "PATCH /admin/category_majors/:id" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      it "大分類一覧にリダイレクト" do
        patch admin_category_major_path(major), params: { category: { name: "更新大分類" } }
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "名前が更新される" do
        patch admin_category_major_path(major), params: { category: { name: "更新大分類" } }
        expect(major.reload.name).to eq("更新大分類")
      end

      it "成功フラッシュが設定される" do
        patch admin_category_major_path(major), params: { category: { name: "更新大分類" } }
        expect(flash[:notice]).to eq("大分類を更新しました")
      end
    end

    context "無効なパラメータの場合（名前空欄）" do
      it "422を返す" do
        patch admin_category_major_path(major), params: { category: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        patch admin_category_major_path(major), params: { category: { name: "更新大分類" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── DELETE /admin/category_majors/:id ───────────────────────────────────
  describe "DELETE /admin/category_majors/:id" do
    before { sign_in admin }

    context "子カテゴリが存在しない場合" do
      it "大分類一覧にリダイレクト" do
        delete admin_category_major_path(major)
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "大分類が削除される" do
        expect {
          delete admin_category_major_path(major)
        }.to change(Category, :count).by(-1)
      end

      it "成功フラッシュが設定される" do
        delete admin_category_major_path(major)
        expect(flash[:notice]).to eq("大分類を削除しました")
      end
    end

    context "子カテゴリが存在する場合" do
      let!(:medium) { create(:category, :medium, parent: major) }

      it "大分類一覧にリダイレクト" do
        delete admin_category_major_path(major)
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "大分類が削除されない" do
        expect {
          delete admin_category_major_path(major)
        }.not_to change(Category, :count)
      end

      it "エラーフラッシュが設定される" do
        delete admin_category_major_path(major)
        expect(flash[:alert]).to be_present
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        delete admin_category_major_path(major)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
