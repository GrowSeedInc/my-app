require "rails_helper"

RSpec.describe "Admin::CategoryMinors", type: :request do
  let!(:admin)  { create(:user, :admin) }
  let(:member)  { create(:user) }
  let!(:major)  { create(:category, name: "大分類") }
  let!(:medium) { create(:category, :medium, name: "中分類", parent: major) }
  let!(:minor)  { create(:category, :minor, name: "小分類テスト", parent: medium) }

  # ─── GET /admin/category_minors/new ──────────────────────────────────────
  describe "GET /admin/category_minors/new" do
    before { sign_in admin }

    it "200を返す" do
      get new_admin_category_minor_path
      expect(response).to have_http_status(:ok)
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get new_admin_category_minor_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── POST /admin/category_minors ─────────────────────────────────────────
  describe "POST /admin/category_minors" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      let(:valid_params) { { category: { name: "新小分類", parent_id: medium.id } } }

      it "カテゴリー管理にリダイレクト" do
        post admin_category_minors_path, params: valid_params
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "小分類が作成される" do
        expect {
          post admin_category_minors_path, params: valid_params
        }.to change(Category.minor, :count).by(1)
      end

      it "成功フラッシュが設定される" do
        post admin_category_minors_path, params: valid_params
        expect(flash[:notice]).to eq("小分類を作成しました")
      end
    end

    context "無効なパラメータの場合（名前空欄）" do
      it "422を返す" do
        post admin_category_minors_path, params: { category: { name: "", parent_id: medium.id } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        post admin_category_minors_path, params: { category: { name: "新小分類", parent_id: medium.id } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── GET /admin/category_minors/:id/edit ─────────────────────────────────
  describe "GET /admin/category_minors/:id/edit" do
    before { sign_in admin }

    it "200を返す" do
      get edit_admin_category_minor_path(minor)
      expect(response).to have_http_status(:ok)
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get edit_admin_category_minor_path(minor)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── PATCH /admin/category_minors/:id ────────────────────────────────────
  describe "PATCH /admin/category_minors/:id" do
    before { sign_in admin }

    context "有効なパラメータの場合" do
      it "カテゴリー管理にリダイレクト" do
        patch admin_category_minor_path(minor), params: { category: { name: "更新小分類", parent_id: medium.id } }
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "名前が更新される" do
        patch admin_category_minor_path(minor), params: { category: { name: "更新小分類", parent_id: medium.id } }
        expect(minor.reload.name).to eq("更新小分類")
      end

      it "成功フラッシュが設定される" do
        patch admin_category_minor_path(minor), params: { category: { name: "更新小分類", parent_id: medium.id } }
        expect(flash[:notice]).to eq("小分類を更新しました")
      end
    end

    context "無効なパラメータの場合（名前空欄）" do
      it "422を返す" do
        patch admin_category_minor_path(minor), params: { category: { name: "", parent_id: medium.id } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        patch admin_category_minor_path(minor), params: { category: { name: "更新小分類", parent_id: medium.id } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── DELETE /admin/category_minors/:id ───────────────────────────────────
  describe "DELETE /admin/category_minors/:id" do
    before { sign_in admin }

    context "備品が紐づいていない場合" do
      it "カテゴリー管理にリダイレクト" do
        delete admin_category_minor_path(minor)
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "小分類が削除される" do
        expect {
          delete admin_category_minor_path(minor)
        }.to change(Category.minor, :count).by(-1)
      end

      it "成功フラッシュが設定される" do
        delete admin_category_minor_path(minor)
        expect(flash[:notice]).to eq("小分類を削除しました")
      end
    end

    context "備品が紐づいている場合" do
      let!(:equipment) { create(:equipment, category: minor) }

      it "カテゴリー管理にリダイレクト" do
        delete admin_category_minor_path(minor)
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "小分類が削除されない" do
        expect {
          delete admin_category_minor_path(minor)
        }.not_to change(Category.minor, :count)
      end

      it "エラーフラッシュが設定される" do
        delete admin_category_minor_path(minor)
        expect(flash[:alert]).to be_present
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        delete admin_category_minor_path(minor)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── GET /admin/category_minors/by_medium ────────────────────────────────
  describe "GET /admin/category_minors/by_medium" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get by_medium_admin_category_minors_path, params: { medium_id: medium.id }
        expect(response).to have_http_status(:ok)
      end

      it "JSONで小分類リストを返す" do
        get by_medium_admin_category_minors_path, params: { medium_id: medium.id }
        json = JSON.parse(response.body)
        expect(json).to include({ "id" => minor.id, "name" => "小分類テスト" })
      end

      it "指定中分類に属する小分類のみ返す" do
        other_medium = create(:category, :medium, name: "別中分類", parent: major)
        other_minor  = create(:category, :minor, name: "別小分類", parent: other_medium)
        get by_medium_admin_category_minors_path, params: { medium_id: medium.id }
        json = JSON.parse(response.body)
        names = json.map { |c| c["name"] }
        expect(names).to include("小分類テスト")
        expect(names).not_to include("別小分類")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "200を返す（認証済みユーザーはアクセス可）" do
        get by_medium_admin_category_minors_path, params: { medium_id: medium.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get by_medium_admin_category_minors_path, params: { medium_id: medium.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
