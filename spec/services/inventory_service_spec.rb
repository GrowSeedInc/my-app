require "rails_helper"

RSpec.describe InventoryService do
  let(:service) { described_class.new }

  describe "#change_status" do
    let(:equipment) { create(:equipment, status: :available) }

    context "修理中ステータスに変更する場合" do
      it "success: true を返す" do
        result = service.change_status(equipment: equipment, status: :repair)
        expect(result[:success]).to be true
      end

      it "ステータスを repair に更新する" do
        service.change_status(equipment: equipment, status: :repair)
        expect(equipment.reload.status).to eq("repair")
      end
    end

    context "廃棄ステータスに変更する場合" do
      it "success: true を返す" do
        result = service.change_status(equipment: equipment, status: :disposed)
        expect(result[:success]).to be true
      end

      it "ステータスを disposed に更新する" do
        service.change_status(equipment: equipment, status: :disposed)
        expect(equipment.reload.status).to eq("disposed")
      end
    end

    context "利用可能ステータスに戻す場合" do
      let(:equipment) { create(:equipment, status: :repair) }

      it "success: true を返す" do
        result = service.change_status(equipment: equipment, status: :available)
        expect(result[:success]).to be true
      end

      it "ステータスを available に更新する" do
        service.change_status(equipment: equipment, status: :available)
        expect(equipment.reload.status).to eq("available")
      end
    end

    context "不正なステータスを指定した場合" do
      it "success: false を返す" do
        result = service.change_status(equipment: equipment, status: "invalid_status")
        expect(result[:success]).to be false
        expect(result[:error]).to eq(:invalid_status)
      end
    end
  end

  describe "#dashboard_summary" do
    let(:cat1) { create(:category, name: "PC機器") }
    let(:cat2) { create(:category, name: "家具") }

    before do
      create(:equipment, category: cat1, total_count: 5, available_count: 3)
      create(:equipment, category: cat1, total_count: 3, available_count: 3)
      create(:equipment, category: cat2, total_count: 10, available_count: 8)
    end

    it "Array を返す" do
      expect(service.dashboard_summary).to be_an(Array)
    end

    it "カテゴリ別に total_count を集計する" do
      summary = service.dashboard_summary
      cat1_row = summary.find { |s| s[:category] == cat1 }
      expect(cat1_row[:total_count]).to eq(8)
    end

    it "カテゴリ別に available_count を集計する" do
      summary = service.dashboard_summary
      cat1_row = summary.find { |s| s[:category] == cat1 }
      expect(cat1_row[:available_count]).to eq(6)
    end

    it "in_use_count を計算する（total - available）" do
      summary = service.dashboard_summary
      cat1_row = summary.find { |s| s[:category] == cat1 }
      expect(cat1_row[:in_use_count]).to eq(2)
    end

    it "equipment_count を返す" do
      summary = service.dashboard_summary
      cat1_row = summary.find { |s| s[:category] == cat1 }
      expect(cat1_row[:equipment_count]).to eq(2)
    end

    it "論理削除された備品は集計対象外" do
      discarded = create(:equipment, category: cat1, total_count: 100, available_count: 100)
      discarded.discard
      summary = service.dashboard_summary
      cat1_row = summary.find { |s| s[:category] == cat1 }
      expect(cat1_row[:total_count]).to eq(8)
    end
  end

  describe "#overdue_loans" do
    it "延滞中（overdue）の貸出のみ返す" do
      overdue = create(:loan, status: :overdue, start_date: Date.today - 10, expected_return_date: Date.today - 3)
      active  = create(:loan, status: :active)
      loans = service.overdue_loans
      expect(loans).to include(overdue)
      expect(loans).not_to include(active)
    end

    it "返却予定日の昇順で並ぶ" do
      loan_later   = create(:loan, status: :overdue, start_date: Date.today - 5,  expected_return_date: Date.today - 1)
      loan_earlier = create(:loan, status: :overdue, start_date: Date.today - 10, expected_return_date: Date.today - 5)
      expect(service.overdue_loans.first).to eq(loan_earlier)
    end

    it "equipment と user を eager load する" do
      create(:loan, status: :overdue, start_date: Date.today - 5, expected_return_date: Date.today - 1)
      loans = service.overdue_loans
      expect(loans.first.association(:equipment).loaded?).to be true
      expect(loans.first.association(:user).loaded?).to be true
    end
  end
end
