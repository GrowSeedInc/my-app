require "rails_helper"

RSpec.describe SearchService do
  let(:service) { described_class.new }

  describe "#search_equipments" do
    let(:cat1) { create(:category, name: "PC機器") }
    let(:cat2) { create(:category, name: "家具") }

    before do
      create(:equipment, name: "ノートPC",    management_number: "PC-001", description: "軽量ノートPC",           category: cat1, total_count: 5,  available_count: 3, status: :available)
      create(:equipment, name: "デスクPC",    management_number: "PC-002", description: "ハイスペックデスクトップ", category: cat1, total_count: 2,  available_count: 0, status: :in_use)
      create(:equipment, name: "会議用椅子",  management_number: "CH-001", description: "キャスター付き",           category: cat2, total_count: 10, available_count: 10, status: :available)
    end

    context "キーワード検索" do
      it "備品名で部分一致検索する" do
        result = service.search_equipments(keyword: "ノート")
        expect(result.records.map(&:name)).to include("ノートPC")
        expect(result.records.map(&:name)).not_to include("会議用椅子")
      end

      it "管理番号で部分一致検索する" do
        result = service.search_equipments(keyword: "CH")
        expect(result.records.map(&:name)).to include("会議用椅子")
        expect(result.records.map(&:name)).not_to include("ノートPC")
      end

      it "説明文で部分一致検索する" do
        result = service.search_equipments(keyword: "キャスター")
        expect(result.records.map(&:name)).to include("会議用椅子")
      end

      it "キーワード未指定は全件返す" do
        result = service.search_equipments
        expect(result.total_count).to eq(3)
      end
    end

    context "カテゴリフィルタ" do
      it "指定カテゴリの備品のみ返す" do
        result = service.search_equipments(category_id: cat1.id)
        expect(result.total_count).to eq(2)
        expect(result.records.map(&:name)).to all(include("PC"))
      end
    end

    context "ステータスフィルタ" do
      it "指定ステータスの備品のみ返す" do
        result = service.search_equipments(status: "in_use")
        expect(result.total_count).to eq(1)
        expect(result.records.first.name).to eq("デスクPC")
      end
    end

    context "ソート" do
      it "名称昇順でソートする" do
        result = service.search_equipments(sort: "name")
        names = result.records.map(&:name)
        expect(names).to eq(names.sort)
      end

      it "在庫数降順でソートする" do
        result = service.search_equipments(sort: "available_count")
        counts = result.records.map(&:available_count)
        expect(counts).to eq(counts.sort.reverse)
      end

      it "不正なsort値はデフォルト（登録日降順）で動く" do
        expect { service.search_equipments(sort: "invalid") }.not_to raise_error
      end
    end

    context "ページネーション" do
      before do
        18.times { |i| create(:equipment, name: "追加備品#{i}", management_number: "EX-#{i.to_s.rjust(3, '0')}") }
      end

      it "total_count は全件数を返す" do
        result = service.search_equipments
        expect(result.total_count).to eq(21)
      end

      it "1ページ目は20件返す" do
        result = service.search_equipments(page: 1)
        expect(result.records.to_a.size).to eq(20)
      end

      it "2ページ目は残り1件を返す" do
        result = service.search_equipments(page: 2)
        expect(result.records.to_a.size).to eq(1)
      end

      it "total_pages を計算する" do
        result = service.search_equipments
        expect(result.total_pages).to eq(2)
      end

      it "1ページ目の next_page は 2" do
        result = service.search_equipments(page: 1)
        expect(result.next_page).to eq(2)
      end

      it "最終ページの next_page は nil" do
        result = service.search_equipments(page: 2)
        expect(result.next_page).to be_nil
      end

      it "2ページ目の prev_page は 1" do
        result = service.search_equipments(page: 2)
        expect(result.prev_page).to eq(1)
      end

      it "先頭ページの prev_page は nil" do
        result = service.search_equipments(page: 1)
        expect(result.prev_page).to be_nil
      end
    end

    it "論理削除された備品は除外する" do
      discarded = create(:equipment, name: "廃棄備品", management_number: "DEL-001")
      discarded.discard
      result = service.search_equipments(keyword: "廃棄")
      expect(result.total_count).to eq(0)
    end
  end

  describe "#search_loans" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:eq1)   { create(:equipment) }
    let(:eq2)   { create(:equipment) }

    before do
      create(:loan, user: user1, equipment: eq1, status: :active,   start_date: Date.today - 5,  expected_return_date: Date.today + 2)
      create(:loan, user: user2, equipment: eq2, status: :returned, start_date: Date.today - 10, expected_return_date: Date.today - 3)
    end

    it "全貸出を返す" do
      result = service.search_loans
      expect(result.total_count).to eq(2)
    end

    it "user_id でフィルタする" do
      result = service.search_loans(user_id: user1.id)
      expect(result.total_count).to eq(1)
      expect(result.records.first.user).to eq(user1)
    end

    it "equipment_id でフィルタする" do
      result = service.search_loans(equipment_id: eq2.id)
      expect(result.total_count).to eq(1)
    end

    it "status でフィルタする" do
      result = service.search_loans(status: "active")
      expect(result.total_count).to eq(1)
      expect(result.records.first.status).to eq("active")
    end

    it "date_from（start_date >= 指定日）でフィルタする" do
      result = service.search_loans(date_from: (Date.today - 6).to_s)
      expect(result.total_count).to eq(1)
    end

    it "date_to（expected_return_date <= 指定日）でフィルタする" do
      result = service.search_loans(date_to: Date.today.to_s)
      expect(result.total_count).to eq(1)
    end
  end
end
