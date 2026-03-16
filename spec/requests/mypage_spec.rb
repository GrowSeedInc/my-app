require "rails_helper"

RSpec.describe "Mypage", type: :request do
  let!(:member)   { create(:user) }
  let(:equipment) { create(:equipment) }

  describe "GET /mypage" do
    context "認証済みの場合" do
      before { sign_in member }

      it "200を返す" do
        get mypage_path
        expect(response).to have_http_status(:ok)
      end

      it "貸出中の備品名が表示される" do
        create(:loan, user: member, equipment: equipment, status: :active)
        get mypage_path
        expect(response.body).to include(equipment.name)
      end

      it "返却済みの貸出も表示される" do
        eq2 = create(:equipment, name: "返却済み備品", management_number: "RET-001")
        create(:loan, user: member, equipment: eq2, status: :returned,
               actual_return_date: Date.today - 1)
        get mypage_path
        expect(response.body).to include("返却済み備品")
      end

      it "他ユーザーの貸出は表示されない" do
        other = create(:user)
        other_eq = create(:equipment, name: "他人の備品", management_number: "OTH-001")
        create(:loan, user: other, equipment: other_eq, status: :active)
        get mypage_path
        expect(response.body).not_to include("他人の備品")
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get mypage_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
