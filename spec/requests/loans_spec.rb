require "rails_helper"

RSpec.describe "Loans", type: :request do
  let!(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }
  let(:equipment) { create(:equipment, total_count: 3, available_count: 3) }

  describe "GET /loans" do
    context "管理者の場合" do
      before { sign_in admin }

      it "全貸出一覧を返す" do
        create(:loan, user: member)
        create(:loan, user: admin)
        get loans_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "自分の貸出一覧を返す" do
        get loans_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get loans_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /loans/new" do
    before { sign_in member }

    it "200を返す" do
      get new_loan_path
      expect(response).to have_http_status(:ok)
    end

    context "未認証の場合" do
      before { sign_out member }

      it "ログイン画面にリダイレクト" do
        get new_loan_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /loans" do
    let(:valid_params) do
      {
        loan: {
          equipment_id: equipment.id,
          start_date: Date.today.to_s,
          expected_return_date: (Date.today + 7).to_s
        }
      }
    end

    context "一般ユーザー・在庫あり" do
      before { sign_in member }

      it "貸出申請を作成して一覧にリダイレクト" do
        expect {
          post loans_path, params: valid_params
        }.to change(Loan, :count).by(1)

        expect(response).to redirect_to(loans_path)
      end

      it "作成された貸出のステータスは pending_approval" do
        post loans_path, params: valid_params
        expect(Loan.last.status).to eq("pending_approval")
      end
    end

    context "在庫がゼロの場合" do
      before do
        sign_in member
        equipment.update!(available_count: 0)
      end

      it "422を返す" do
        post loans_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "バリデーションエラーの場合" do
      before { sign_in member }

      it "422を返す" do
        post loans_path, params: {
          loan: { equipment_id: equipment.id, start_date: Date.today.to_s, expected_return_date: Date.today.to_s }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        post loans_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /loans/:id/approve" do
    let!(:loan) { create(:loan, status: :pending_approval, user: member) }

    context "管理者の場合" do
      before { sign_in admin }

      it "貸出を承認して一覧にリダイレクト" do
        patch approve_loan_path(loan)
        expect(response).to redirect_to(loans_path)
        expect(loan.reload.status).to eq("active")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        patch approve_loan_path(loan)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
