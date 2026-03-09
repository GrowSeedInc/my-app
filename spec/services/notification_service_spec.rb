require "rails_helper"

RSpec.describe NotificationService do
  let(:service) { described_class.new }
  let(:member)    { create(:user, email: "member@example.com") }
  let(:equipment) { create(:equipment, name: "テスト備品", low_stock_threshold: 2) }
  let(:loan)      { create(:loan, user: member, equipment: equipment, status: :active) }

  describe "#send_loan_confirmation" do
    it "LoanMailer#loan_confirmation をキューに積む" do
      expect {
        service.send_loan_confirmation(loan: loan)
      }.to have_enqueued_mail(LoanMailer, :loan_confirmation).with(loan)
    end

    it "メール送信エラーが発生してもrescueして処理を継続する" do
      allow(LoanMailer).to receive(:loan_confirmation).and_raise(StandardError, "SMTP error")
      expect { service.send_loan_confirmation(loan: loan) }.not_to raise_error
    end
  end

  describe "#send_low_stock_alert" do
    it "LoanMailer#low_stock_alert をキューに積む" do
      expect {
        service.send_low_stock_alert(equipment: equipment)
      }.to have_enqueued_mail(LoanMailer, :low_stock_alert).with(equipment)
    end

    it "メール送信エラーが発生してもrescueして処理を継続する" do
      allow(LoanMailer).to receive(:low_stock_alert).and_raise(StandardError, "SMTP error")
      expect { service.send_low_stock_alert(equipment: equipment) }.not_to raise_error
    end
  end

  describe "#send_overdue_alert" do
    it "LoanMailer#overdue_alert をキューに積む" do
      expect {
        service.send_overdue_alert(loan: loan)
      }.to have_enqueued_mail(LoanMailer, :overdue_alert).with(loan)
    end

    it "メール送信エラーが発生してもrescueして処理を継続する" do
      allow(LoanMailer).to receive(:overdue_alert).and_raise(StandardError, "SMTP error")
      expect { service.send_overdue_alert(loan: loan) }.not_to raise_error
    end
  end
end
