require "rails_helper"

RSpec.describe "Loans Return", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:member)   { create(:user) }
  let(:equipment) { create(:equipment, total_count: 3, available_count: 2) }

  describe "PATCH /loans/:id/return" do
    context "貸出申請者本人の場合" do
      let!(:loan) { create(:loan, user: member, equipment: equipment, status: :active) }
      before { sign_in member }

      it "返却処理して貸出一覧にリダイレクト" do
        patch return_loan_path(loan)
        expect(response).to redirect_to(loans_path)
      end

      it "ステータスが returned になる" do
        patch return_loan_path(loan)
        expect(loan.reload.status).to eq("returned")
      end

      it "備品の貸出可能数が1増加する" do
        expect {
          patch return_loan_path(loan)
        }.to change { equipment.reload.available_count }.by(1)
      end
    end

    context "管理者の場合" do
      let!(:loan) { create(:loan, user: member, equipment: equipment, status: :active) }
      before { sign_in admin }

      it "返却処理して貸出一覧にリダイレクト" do
        patch return_loan_path(loan)
        expect(response).to redirect_to(loans_path)
        expect(loan.reload.status).to eq("returned")
      end
    end

    context "他ユーザーの貸出に対する場合" do
      let(:other_member) { create(:user) }
      let!(:loan) { create(:loan, user: other_member, equipment: equipment, status: :active) }
      before { sign_in member }

      it "403を返す" do
        patch return_loan_path(loan)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "延滞中（overdue）のローンの場合" do
      let!(:loan) { create(:loan, user: member, equipment: equipment, status: :overdue) }
      before { sign_in member }

      it "返却処理して貸出一覧にリダイレクト" do
        patch return_loan_path(loan)
        expect(response).to redirect_to(loans_path)
        expect(loan.reload.status).to eq("returned")
      end
    end

    context "返却不可能なステータス（pending_approval）のローンの場合" do
      let!(:loan) { create(:loan, user: member, equipment: equipment, status: :pending_approval) }
      before { sign_in member }

      it "422を返す" do
        patch return_loan_path(loan)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "未認証の場合" do
      let!(:loan) { create(:loan, user: member, equipment: equipment, status: :active) }

      it "ログイン画面にリダイレクト" do
        patch return_loan_path(loan)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
