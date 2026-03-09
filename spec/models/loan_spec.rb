require "rails_helper"

RSpec.describe Loan, type: :model do
  describe "バリデーション" do
    it "必須項目がすべて揃っていれば有効である" do
      loan = build(:loan)
      expect(loan).to be_valid
    end

    it "開始日が必須である" do
      loan = build(:loan, start_date: nil)
      expect(loan).not_to be_valid
      expect(loan.errors[:start_date]).to be_present
    end

    it "返却予定日が必須である" do
      loan = build(:loan, expected_return_date: nil)
      expect(loan).not_to be_valid
      expect(loan.errors[:expected_return_date]).to be_present
    end

    it "返却予定日が開始日より後である場合は有効である" do
      loan = build(:loan, start_date: Date.today, expected_return_date: Date.today + 1)
      expect(loan).to be_valid
    end

    it "返却予定日が開始日と同日の場合は無効である" do
      loan = build(:loan, start_date: Date.today, expected_return_date: Date.today)
      expect(loan).not_to be_valid
      expect(loan.errors[:expected_return_date]).to be_present
    end

    it "返却予定日が開始日より前の場合は無効である" do
      loan = build(:loan, start_date: Date.today, expected_return_date: Date.today - 1)
      expect(loan).not_to be_valid
      expect(loan.errors[:expected_return_date]).to be_present
    end

    it "実返却日はnilでも有効である" do
      loan = build(:loan, actual_return_date: nil)
      expect(loan).to be_valid
    end
  end

  describe "ステータスenum" do
    it "デフォルトステータスはpending_approvalである" do
      loan = build(:loan)
      expect(loan.status).to eq("pending_approval")
    end

    it "pending_approvalステータスを設定できる" do
      loan = build(:loan, status: :pending_approval)
      expect(loan).to be_pending_approval
    end

    it "activeステータスを設定できる" do
      loan = build(:loan, status: :active)
      expect(loan).to be_active
    end

    it "returnedステータスを設定できる" do
      loan = build(:loan, status: :returned)
      expect(loan).to be_returned
    end

    it "overdueステータスを設定できる" do
      loan = build(:loan, status: :overdue)
      expect(loan).to be_overdue
    end
  end

  describe "アソシエーション" do
    it "備品に属する" do
      equipment = create(:equipment)
      loan = build(:loan, equipment: equipment)
      expect(loan.equipment).to eq(equipment)
    end

    it "ユーザーに属する" do
      user = create(:user)
      loan = build(:loan, user: user)
      expect(loan.user).to eq(user)
    end

    it "備品が必須である" do
      loan = build(:loan, equipment: nil)
      expect(loan).not_to be_valid
      expect(loan.errors[:equipment]).to be_present
    end

    it "ユーザーが必須である" do
      loan = build(:loan, user: nil)
      expect(loan).not_to be_valid
      expect(loan.errors[:user]).to be_present
    end
  end
end
