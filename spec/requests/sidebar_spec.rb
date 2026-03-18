require "rails_helper"

RSpec.describe "サイドバー HTML 出力", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }

  describe "GET /equipments (ログイン済み一般ユーザー)" do
    before { sign_in member }

    it 'レスポンスに data-controller="sidebar" が含まれる' do
      get equipments_path
      expect(response.body).to include('data-controller="sidebar"')
    end

    it "管理者専用リンク（ダッシュボード）が含まれない" do
      get equipments_path
      expect(response.body).not_to include(admin_dashboard_path)
    end

    it "管理者専用リンク（ユーザー管理）が含まれない" do
      get equipments_path
      expect(response.body).not_to include(admin_users_path)
    end

    it "管理者専用リンク（カテゴリ管理）が含まれない" do
      get equipments_path
      expect(response.body).not_to include(admin_category_majors_path)
    end
  end

  describe "GET /equipments (ログイン済み管理者)" do
    before { sign_in admin }

    it "管理者専用リンク（ダッシュボード）が含まれる" do
      get equipments_path
      expect(response.body).to include(admin_dashboard_path)
    end

    it "管理者専用リンク（ユーザー管理）が含まれる" do
      get equipments_path
      expect(response.body).to include(admin_users_path)
    end

    it "管理者専用リンク（カテゴリ管理）が含まれる" do
      get equipments_path
      expect(response.body).to include(admin_category_majors_path)
    end
  end

  describe "GET /users/sign_in (未ログイン)" do
    it 'サイドバー HTML が含まれない' do
      get new_user_session_path
      expect(response.body).not_to include('data-controller="sidebar"')
    end
  end
end
