require "rails_helper"

# 備品検索・フィルタ・ページネーション・ダッシュボードの統合テスト
RSpec.describe "備品検索・一覧表示", type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:member) { create(:user) }
  let(:category_a) { create(:category, :minor, name: "PCカテゴリ") }
  let(:category_b) { create(:category, :minor, name: "家具カテゴリ") }

  before { sign_in member }

  describe "キーワード検索" do
    let!(:macbook)  { create(:equipment, name: "MacBook Pro", management_number: "PC-001") }
    let!(:ipad)     { create(:equipment, name: "iPad",        management_number: "TAB-001") }
    let!(:desk)     { create(:equipment, name: "会議用デスク",  management_number: "FRN-001") }

    it "備品名で部分一致検索できる" do
      get equipments_path, params: { keyword: "Mac" }
      expect(response.body).to include("MacBook Pro")
      expect(response.body).not_to include("iPad")
      expect(response.body).not_to include("会議用デスク")
    end

    it "管理番号で部分一致検索できる" do
      get equipments_path, params: { keyword: "TAB" }
      expect(response.body).to include("iPad")
      expect(response.body).not_to include("MacBook Pro")
    end
  end

  describe "カテゴリフィルタ" do
    let!(:pc_eq)  { create(:equipment, name: "ノートPC",   management_number: "PC-010", category: category_a) }
    let!(:furn_eq) { create(:equipment, name: "椅子",       management_number: "FRN-010", category: category_b) }
    let!(:no_cat)  { create(:equipment, name: "カテゴリなし", management_number: "NOC-001", category: nil) }

    it "カテゴリで絞り込みできる" do
      get equipments_path, params: { category_minor_id: category_a.id }
      expect(response.body).to include("ノートPC")
      expect(response.body).not_to include("椅子")
    end
  end

  describe "ステータスフィルタ" do
    let!(:avail_eq)  { create(:equipment, name: "利用可能備品",  management_number: "AV-001", status: :available) }
    let!(:repair_eq) { create(:equipment, name: "修理中備品",    management_number: "RP-001", status: :repair) }

    it "ステータスで絞り込みできる" do
      get equipments_path, params: { status: "repair" }
      expect(response.body).to include("修理中備品")
      expect(response.body).not_to include("利用可能備品")
    end
  end

  describe "ページネーション" do
    before do
      # 21件作成（1ページ20件 → 2ページに分割）
      21.times do |i|
        create(:equipment, name: "備品#{format('%03d', i + 1)}",
               management_number: "PG-#{format('%03d', i + 1)}")
      end
    end

    it "1ページ目は20件表示される" do
      get equipments_path, params: { page: 1 }
      expect(response).to have_http_status(:ok)
      # ページネーションUIが表示されている
      expect(response.body).to include("次へ →")
    end

    it "2ページ目は残り1件が表示される" do
      get equipments_path, params: { page: 2 }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("← 前へ")
    end
  end

  describe "管理者ダッシュボードのサマリー精度" do
    before { sign_out member; sign_in admin }

    it "カテゴリ別の在庫数が正確に表示される" do
      major    = create(:category, name: "精度テスト大分類")
      medium   = create(:category, :medium, name: "精度テスト中分類", parent: major)
      minor    = create(:category, :minor,  name: "精度テスト小分類", parent: medium)
      create(:equipment, name: "備品A", management_number: "ACC-001",
             category: minor, total_count: 5, available_count: 3)
      create(:equipment, name: "備品B", management_number: "ACC-002",
             category: minor, total_count: 3, available_count: 3)

      get admin_dashboard_path
      expect(response.body).to include("精度テスト大分類")
      # 総数 5+3=8、利用可能 3+3=6
      expect(response.body).to include("8")
      expect(response.body).to include("6")
    end

    it "延滞日数が正確に計算される" do
      overdue_loan = create(:loan,
                            status: :overdue,
                            start_date: Date.today - 10,
                            expected_return_date: Date.today - 5)
      get admin_dashboard_path
      expect(response.body).to include("5") # 5日延滞
    end
  end
end
