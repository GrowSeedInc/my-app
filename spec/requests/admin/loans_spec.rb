require "rails_helper"

RSpec.describe "Admin::Loans", type: :request do
  let!(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }
  let(:target_user) { create(:user) }
  let(:equipment) { create(:equipment, total_count: 3, available_count: 3) }

  describe "GET /admin/loans/new" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get new_admin_loan_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get new_admin_loan_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get new_admin_loan_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /admin/loans" do
    before { sign_in admin }

    let(:valid_params) do
      {
        loan: {
          user_id: target_user.id,
          equipment_id: equipment.id,
          start_date: Date.today,
          expected_return_date: Date.today + 7,
          mode: "apply"
        }
      }
    end

    context "代理申請モード（mode: apply）で成功する場合" do
      it "pending_approval の Loan が作成される" do
        expect {
          post admin_loans_path, params: valid_params
        }.to change(Loan, :count).by(1)

        expect(Loan.last.status).to eq("pending_approval")
        expect(Loan.last.user).to eq(target_user)
      end

      it "貸出一覧にリダイレクトする" do
        post admin_loans_path, params: valid_params
        expect(response).to redirect_to(loans_path)
      end
    end

    context "直接記録モード（mode: direct）で成功する場合" do
      let(:direct_params) do
        valid_params.deep_merge(loan: { mode: "direct" })
      end

      it "active の Loan が作成される" do
        expect {
          post admin_loans_path, params: direct_params
        }.to change(Loan, :count).by(1)

        expect(Loan.last.status).to eq("active")
        expect(Loan.last.user).to eq(target_user)
      end

      it "貸出一覧にリダイレクトする" do
        post admin_loans_path, params: direct_params
        expect(response).to redirect_to(loans_path)
      end
    end

    context "バリデーションエラーの場合" do
      let(:invalid_params) do
        {
          loan: {
            user_id: target_user.id,
            equipment_id: equipment.id,
            start_date: Date.today,
            expected_return_date: Date.today - 1,
            mode: "apply"
          }
        }
      end

      it "422を返しフォームを再表示する" do
        post admin_loans_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーがアクセスした場合" do
      before { sign_in member }

      it "403を返す" do
        post admin_loans_path, params: valid_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
