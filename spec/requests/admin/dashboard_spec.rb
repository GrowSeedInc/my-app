require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let!(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }

  describe "GET /admin/dashboard" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get admin_dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it "カテゴリ別サマリーを表示する" do
        category = create(:category, name: "テストカテゴリ")
        create(:equipment, category: category, total_count: 5, available_count: 3)
        get admin_dashboard_path
        expect(response.body).to include("テストカテゴリ")
      end

      it "延滞中の貸出を表示する" do
        overdue_loan = create(:loan, status: :overdue, start_date: Date.today - 10, expected_return_date: Date.today - 3)
        get admin_dashboard_path
        expect(response.body).to include(overdue_loan.equipment.name)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get admin_dashboard_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get admin_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
