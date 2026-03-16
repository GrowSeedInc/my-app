require "rails_helper"

RSpec.describe OverdueCheckJob, type: :job do
  let(:equipment) { create(:equipment) }
  let(:member)    { create(:user) }

  describe "#perform" do
    context "返却予定日を過ぎた active ローンがある場合" do
      let!(:overdue_loan) do
        create(:loan, user: member, equipment: equipment,
               status: :active,
               start_date: Date.today - 10,
               expected_return_date: Date.today - 1)
      end

      it "ステータスを overdue に更新する" do
        described_class.perform_now
        expect(overdue_loan.reload.status).to eq("overdue")
      end

      it "延滞件数分だけ overdue_alert メールをキューに積む" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(LoanMailer, :overdue_alert)
      end
    end

    context "返却予定日が今日のローンがある場合" do
      let!(:due_today_loan) do
        create(:loan, user: member, equipment: equipment,
               status: :active,
               start_date: Date.today - 5,
               expected_return_date: Date.today)
      end

      it "ステータスを変更しない" do
        described_class.perform_now
        expect(due_today_loan.reload.status).to eq("active")
      end
    end

    context "返却予定日が未来の active ローンがある場合" do
      let!(:future_loan) do
        create(:loan, user: member, equipment: equipment,
               status: :active,
               start_date: Date.today,
               expected_return_date: Date.today + 7)
      end

      it "ステータスを変更しない" do
        described_class.perform_now
        expect(future_loan.reload.status).to eq("active")
      end
    end

    context "既に overdue のローンがある場合（冪等性）" do
      let!(:already_overdue) do
        create(:loan, user: member, equipment: equipment,
               status: :overdue,
               start_date: Date.today - 10,
               expected_return_date: Date.today - 3)
      end

      it "重複処理されない（追加のメールが送られない）" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(LoanMailer, :overdue_alert)
      end

      it "ステータスは overdue のまま変わらない" do
        described_class.perform_now
        expect(already_overdue.reload.status).to eq("overdue")
      end
    end

    context "複数の延滞ローンがある場合" do
      let(:equipment2) { create(:equipment) }
      let!(:loan1) do
        create(:loan, user: member, equipment: equipment,
               status: :active,
               start_date: Date.today - 10,
               expected_return_date: Date.today - 2)
      end
      let!(:loan2) do
        create(:loan, user: create(:user), equipment: equipment2,
               status: :active,
               start_date: Date.today - 8,
               expected_return_date: Date.today - 1)
      end

      it "全ての延滞ローンを overdue に更新する" do
        described_class.perform_now
        expect(loan1.reload.status).to eq("overdue")
        expect(loan2.reload.status).to eq("overdue")
      end

      it "延滞件数分のメールをキューに積む" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(LoanMailer, :overdue_alert).exactly(2).times
      end
    end
  end
end
