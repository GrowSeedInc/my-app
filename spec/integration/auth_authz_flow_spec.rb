require "rails_helper"

# 認証・認可のE2Eテスト
# 複数ステップを跨ぐ全フローを検証する
RSpec.describe "認証・認可フロー", type: :request do
  let!(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }

  describe "管理者によるユーザー登録〜貸出申請の全フロー" do
    let(:equipment) { create(:equipment, total_count: 1, available_count: 1) }

    it "管理者が作成したユーザーが貸出申請できる" do
      # 1. 管理者がユーザーを作成
      sign_in admin
      post admin_users_path, params: {
        user: {
          name: "新規メンバー",
          email: "newmember@example.com",
          password: "password123",
          role: "member"
        }
      }
      expect(response).to redirect_to(admin_users_path)
      new_user = User.find_by!(email: "newmember@example.com")
      expect(new_user.name).to eq("新規メンバー")
      expect(new_user.role).to eq("member")

      # 2. 作成されたユーザーでサインイン
      sign_out admin
      sign_in new_user

      # 3. 備品一覧が閲覧できる
      get equipments_path
      expect(response).to have_http_status(:ok)

      # 4. 貸出申請できる
      post loans_path, params: {
        loan: {
          equipment_id: equipment.id,
          start_date: Date.today.to_s,
          expected_return_date: (Date.today + 7).to_s
        }
      }
      expect(response).to redirect_to(loans_path)
      loan = Loan.find_by!(user: new_user)
      expect(loan.status).to eq("pending_approval")

      # 5. 管理者が承認
      sign_out new_user
      sign_in admin
      patch approve_loan_path(loan)
      expect(response).to redirect_to(loans_path)
      expect(loan.reload.status).to eq("active")
    end
  end

  describe "未認証ユーザーのアクセス制御" do
    it "備品一覧はログイン画面にリダイレクト" do
      get equipments_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "貸出一覧はログイン画面にリダイレクト" do
      get loans_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "管理者ダッシュボードはログイン画面にリダイレクト" do
      get admin_dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "ユーザー管理画面はログイン画面にリダイレクト" do
      get admin_users_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "マイページはログイン画面にリダイレクト" do
      get mypage_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "一般ユーザーの権限制限" do
    before { sign_in member }

    it "管理者ダッシュボードへのアクセスは403" do
      get admin_dashboard_path
      expect(response).to have_http_status(:forbidden)
    end

    it "ユーザー管理一覧へのアクセスは403" do
      get admin_users_path
      expect(response).to have_http_status(:forbidden)
    end

    it "備品登録フォームへのアクセスは403" do
      get new_equipment_path
      expect(response).to have_http_status(:forbidden)
    end

    it "備品削除は403" do
      equipment = create(:equipment)
      delete equipment_path(equipment)
      expect(response).to have_http_status(:forbidden)
    end

    it "他ユーザーのローン承認は403" do
      other_loan = create(:loan, user: create(:user), status: :pending_approval)
      patch approve_loan_path(other_loan)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "ロール変更の即時反映" do
    let!(:target_user) { create(:user, role: :member) }

    it "管理者が一般ユーザーをadminに昇格できる" do
      sign_in admin
      patch admin_user_path(target_user), params: { user: { role: "admin" } }
      expect(response).to redirect_to(admin_users_path)
      expect(target_user.reload.role).to eq("admin")

      # 昇格後は管理者ダッシュボードにアクセスできる
      sign_out admin
      sign_in target_user
      get admin_dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end
end
