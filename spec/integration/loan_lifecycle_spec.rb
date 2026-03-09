require "rails_helper"

# 貸出・返却フローの統合テスト
# 複数のコンポーネント（Controller → Service → Model）を跨ぐシナリオを検証する
RSpec.describe "貸出・返却ライフサイクル", type: :request do
  let(:admin)     { create(:user, :admin) }
  let(:member)    { create(:user) }
  let(:equipment) { create(:equipment, total_count: 2, available_count: 2) }

  describe "通常フロー: 申請 → 承認 → 返却" do
    it "一連のステップが正常に完了する" do
      # 1. 一般ユーザーが貸出申請
      sign_in member
      post loans_path, params: {
        loan: {
          equipment_id: equipment.id,
          start_date: Date.today.to_s,
          expected_return_date: (Date.today + 7).to_s
        }
      }
      expect(response).to redirect_to(loans_path)

      loan = Loan.last
      expect(loan.status).to eq("pending_approval")
      expect(equipment.reload.available_count).to eq(1)

      # 2. 管理者が承認
      sign_out member
      sign_in admin
      patch approve_loan_path(loan)
      expect(response).to redirect_to(loans_path)
      expect(loan.reload.status).to eq("active")

      # 3. ユーザーが返却
      sign_out admin
      sign_in member
      patch return_loan_path(loan)
      expect(response).to redirect_to(loans_path)
      expect(loan.reload.status).to eq("returned")
      expect(loan.reload.actual_return_date).to eq(Date.today)
      expect(equipment.reload.available_count).to eq(2)
    end
  end

  describe "在庫なしフロー" do
    before { equipment.update!(available_count: 0) }

    it "在庫ゼロの備品への申請は422で拒否される" do
      sign_in member
      post loans_path, params: {
        loan: {
          equipment_id: equipment.id,
          start_date: Date.today.to_s,
          expected_return_date: (Date.today + 7).to_s
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Loan.count).to eq(0)
      expect(equipment.reload.available_count).to eq(0)
    end
  end

  describe "在庫1件・同時申請フロー" do
    let(:equipment1) { create(:equipment, total_count: 1, available_count: 1) }
    let(:member2)    { create(:user) }

    it "1件のみ成功し、もう1件は在庫不足になる" do
      params = {
        loan: {
          equipment_id: equipment1.id,
          start_date: Date.today.to_s,
          expected_return_date: (Date.today + 7).to_s
        }
      }

      # 2ユーザーが並行して申請（シリアルに実行）
      sign_in member
      post loans_path, params: params
      result1_status = response.status

      sign_out member
      sign_in member2
      post loans_path, params: params
      result2_status = response.status

      # 一方が成功（302）、もう一方が失敗（422）
      statuses = [result1_status, result2_status]
      expect(statuses).to include(302)
      expect(statuses).to include(422)
      expect(Loan.count).to eq(1)
      expect(equipment1.reload.available_count).to eq(0)
    end
  end

  describe "延滞後の返却フロー" do
    let!(:overdue_loan) do
      create(:loan, user: member, equipment: equipment,
             status: :overdue,
             start_date: Date.today - 14,
             expected_return_date: Date.today - 7)
    end

    it "延滞中のローンも正常に返却できる" do
      sign_in member
      patch return_loan_path(overdue_loan)
      expect(response).to redirect_to(loans_path)
      expect(overdue_loan.reload.status).to eq("returned")
      expect(overdue_loan.reload.actual_return_date).to eq(Date.today)
      expect(equipment.reload.available_count).to eq(3) # 元の2 + 1
    end
  end

  describe "認可: 他ユーザーの貸出への操作" do
    let(:other_member) { create(:user) }
    let!(:loan) do
      create(:loan, user: other_member, equipment: equipment, status: :active)
    end

    it "他ユーザーのローンは返却できない（403）" do
      sign_in member
      patch return_loan_path(loan)
      expect(response).to have_http_status(:forbidden)
      expect(loan.reload.status).to eq("active")
    end
  end
end
