require "rails_helper"

RSpec.describe LoanMailer, type: :mailer do
  let(:member)    { create(:user, name: "田中 太郎", email: "taro@example.com") }
  let(:equipment) { create(:equipment, name: "MacBook Pro", management_number: "PC-001") }
  let(:loan) do
    create(:loan, user: member, equipment: equipment,
           start_date: Date.new(2026, 3, 10),
           expected_return_date: Date.new(2026, 3, 17),
           status: :active)
  end

  describe "#loan_confirmation" do
    let(:mail) { described_class.loan_confirmation(loan) }

    it "申請者のメールアドレスに送信される" do
      expect(mail.to).to include("taro@example.com")
    end

    it "件名に「貸出」が含まれる" do
      expect(mail.subject).to include("貸出")
    end

    it "本文に備品名が含まれる" do
      expect(mail.text_part.decoded).to include("MacBook Pro")
    end

    it "本文に管理番号が含まれる" do
      expect(mail.text_part.decoded).to include("PC-001")
    end

    it "本文に貸出開始日が含まれる" do
      expect(mail.text_part.decoded).to include("2026")
    end

    it "本文に返却予定日が含まれる" do
      expect(mail.text_part.decoded).to include("2026/03/17")
    end
  end

  describe "#low_stock_alert" do
    let!(:admin1) { create(:user, :admin, email: "admin1@example.com") }
    let!(:admin2) { create(:user, :admin, email: "admin2@example.com") }
    let(:low_equipment) do
      create(:equipment, name: "iPad", management_number: "TAB-001",
             available_count: 1, low_stock_threshold: 3)
    end
    let(:mail) { described_class.low_stock_alert(low_equipment) }

    it "全管理者のメールアドレスに送信される" do
      expect(mail.to).to include("admin1@example.com")
      expect(mail.to).to include("admin2@example.com")
    end

    it "件名に備品名が含まれる" do
      expect(mail.subject).to include("iPad")
    end

    it "本文に貸出可能数が含まれる" do
      expect(mail.text_part.decoded).to include("1")
    end

    it "本文に管理番号が含まれる" do
      expect(mail.text_part.decoded).to include("TAB-001")
    end
  end
end
