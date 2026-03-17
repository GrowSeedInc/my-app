require "rails_helper"

RSpec.describe "Admin::CategoryMediums", type: :request do
  let!(:admin)  { create(:user, :admin) }
  let(:member)  { create(:user) }
  let!(:major)  { create(:category, name: "大分類") }
  let!(:medium) { create(:category, :medium, name: "中分類テスト", parent: major) }

  # ─── GET /admin/category_mediums ─────────────────────────────────────────
  describe "GET /admin/category_mediums" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get admin_category_mediums_path
        expect(response).to have_http_status(:ok)
      end

      it "中分類名が表示される" do
        get admin_category_mediums_path
        expect(response.body).to include("中分類テスト")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get admin_category_mediums_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get admin_category_mediums_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── GET /admin/category_mediums/new ─────────────────────────────────────
  describe "GET /admin/category_mediums/new" do
    before { sign_in admin }

    it "200を返す" do
      get new_admin_category_medium_path
      expect(response).to have_http_status(:ok)
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get new_admin_category_medium_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── POST /admin/category_mediums ────────────────────────────────────────
  describe "POST /admin/category_mediums" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      let(:valid_params) { { category: { name: "新中分類", parent_id: major.id } } }

      it "中分類一覧にリダイレクト" do
        post admin_category_mediums_path, params: valid_params
        expect(response).to redirect_to(admin_category_mediums_path)
      end

      it "中分類が作成される" do
        expect {
          post admin_category_mediums_path, params: valid_params
        }.to change(Category.medium, :count).by(1)
      end

      it "成功フラッシュが設定される" do
        post admin_category_mediums_path, params: valid_params
        expect(flash[:notice]).to eq("中分類を作成しました")
      end
    end

    context "無効なパラメータの場合（名前空欄）" do
      it "422を返す" do
        post admin_category_mediums_path, params: { category: { name: "", parent_id: major.id } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        post admin_category_mediums_path, params: { category: { name: "新中分類", parent_id: major.id } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── GET /admin/category_mediums/:id/edit ────────────────────────────────
  describe "GET /admin/category_mediums/:id/edit" do
    before { sign_in admin }

    it "200を返す" do
      get edit_admin_category_medium_path(medium)
      expect(response).to have_http_status(:ok)
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get edit_admin_category_medium_path(medium)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── PATCH /admin/category_mediums/:id ───────────────────────────────────
  describe "PATCH /admin/category_mediums/:id" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      it "中分類一覧にリダイレクト" do
        patch admin_category_medium_path(medium), params: { category: { name: "更新中分類", parent_id: major.id } }
        expect(response).to redirect_to(admin_category_mediums_path)
      end

      it "名前が更新される" do
        patch admin_category_medium_path(medium), params: { category: { name: "更新中分類", parent_id: major.id } }
        expect(medium.reload.name).to eq("更新中分類")
      end

      it "成功フラッシュが設定される" do
        patch admin_category_medium_path(medium), params: { category: { name: "更新中分類", parent_id: major.id } }
        expect(flash[:notice]).to eq("中分類を更新しました")
      end
    end

    context "無効なパラメータの場合（名前空欄）" do
      it "422を返す" do
        patch admin_category_medium_path(medium), params: { category: { name: "", parent_id: major.id } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        patch admin_category_medium_path(medium), params: { category: { name: "更新中分類", parent_id: major.id } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── DELETE /admin/category_mediums/:id ──────────────────────────────────
  describe "DELETE /admin/category_mediums/:id" do
    before { sign_in admin }

    context "子カテゴリが存在しない場合" do
      it "中分類一覧にリダイレクト" do
        delete admin_category_medium_path(medium)
        expect(response).to redirect_to(admin_category_mediums_path)
      end

      it "中分類が削除される" do
        expect {
          delete admin_category_medium_path(medium)
        }.to change(Category.medium, :count).by(-1)
      end

      it "成功フラッシュが設定される" do
        delete admin_category_medium_path(medium)
        expect(flash[:notice]).to eq("中分類を削除しました")
      end
    end

    context "子カテゴリ（小分類）が存在する場合" do
      let!(:minor) { create(:category, :minor, parent: medium) }

      it "中分類一覧にリダイレクト" do
        delete admin_category_medium_path(medium)
        expect(response).to redirect_to(admin_category_mediums_path)
      end

      it "中分類が削除されない" do
        expect {
          delete admin_category_medium_path(medium)
        }.not_to change(Category.medium, :count)
      end

      it "エラーフラッシュが設定される" do
        delete admin_category_medium_path(medium)
        expect(flash[:alert]).to be_present
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        delete admin_category_medium_path(medium)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── GET /admin/category_mediums/by_major ────────────────────────────────
  describe "GET /admin/category_mediums/by_major" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get by_major_admin_category_mediums_path, params: { major_id: major.id }
        expect(response).to have_http_status(:ok)
      end

      it "JSONで中分類リストを返す" do
        get by_major_admin_category_mediums_path, params: { major_id: major.id }
        json = JSON.parse(response.body)
        expect(json).to include({ "id" => medium.id, "name" => "中分類テスト" })
      end

      it "指定大分類に属する中分類のみ返す" do
        other_major  = create(:category, name: "別大分類")
        other_medium = create(:category, :medium, name: "別中分類", parent: other_major)
        get by_major_admin_category_mediums_path, params: { major_id: major.id }
        json = JSON.parse(response.body)
        names = json.map { |c| c["name"] }
        expect(names).to include("中分類テスト")
        expect(names).not_to include("別中分類")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "200を返す（認証済みユーザーはアクセス可）" do
        get by_major_admin_category_mediums_path, params: { major_id: major.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get by_major_admin_category_mediums_path, params: { major_id: major.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
