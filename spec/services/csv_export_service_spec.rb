require "rails_helper"
require "csv"

RSpec.describe CsvExportService do
  let(:service) { described_class.new }
  let(:bom) { "\xEF\xBB\xBF" }

  describe "#export_equipments" do
    let(:major)    { create(:category, name: "PC機器") }
    let(:medium)   { create(:category, :medium, name: "ノートPC類", parent: major) }
    let(:category) { create(:category, :minor, name: "ThinkPad", parent: medium) }
    let!(:equipment) do
      create(:equipment,
        name: "ノートPC",
        management_number: "EQ-001",
        category: category,
        status: :available,
        total_count: 5,
        available_count: 3,
        description: "テスト用PC"
      )
    end
    let!(:discarded_equipment) do
      e = create(:equipment, name: "廃棄備品", management_number: "EQ-999")
      e.discard
      e
    end

    subject(:csv_string) { service.export_equipments(Equipment.kept) }

    it "UTF-8 BOMで始まる" do
      expect(csv_string).to start_with(bom)
    end

    it "正しいヘッダー行を含む" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      expect(rows[0]).to eq(%w[備品名 管理番号 カテゴリ ステータス 在庫数 貸出中数 説明])
    end

    it "備品データを正しく出力する（階層パス形式）" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      expect(rows[1]).to eq(["ノートPC", "EQ-001", "PC機器 > ノートPC類 > ThinkPad", "available", "5", "2", "テスト用PC"])
    end

    it "ソフトデリート済み備品を含まない" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      names = rows[1..].map { |r| r[0] }
      expect(names).not_to include("廃棄備品")
    end

    it "カテゴリがない備品は空文字を出力する" do
      create(:equipment, name: "カテゴリなし備品", management_number: "EQ-002", category: nil)
      rows = CSV.parse(service.export_equipments(Equipment.kept).sub(bom, ""))
      no_cat_row = rows[1..].find { |r| r[0] == "カテゴリなし備品" }
      expect(no_cat_row[2]).to eq("")
    end
  end

  describe "#export_loans" do
    let(:user) { create(:user, name: "田中太郎") }
    let(:equipment) { create(:equipment, name: "プロジェクター") }
    let!(:loan) do
      create(:loan,
        equipment: equipment,
        user: user,
        start_date: Date.new(2026, 3, 1),
        expected_return_date: Date.new(2026, 3, 10),
        actual_return_date: Date.new(2026, 3, 9),
        status: :returned
      )
    end

    subject(:csv_string) { service.export_loans(Loan.all) }

    it "UTF-8 BOMで始まる" do
      expect(csv_string).to start_with(bom)
    end

    it "正しいヘッダー行を含む" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      expect(rows[0]).to eq(%w[備品名 貸出者名 申請日 承認日 予定返却日 実返却日 ステータス])
    end

    it "貸出データを正しく出力する" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      expect(rows[1][0]).to eq("プロジェクター")
      expect(rows[1][1]).to eq("田中太郎")
      expect(rows[1][4]).to eq("2026-03-10")
      expect(rows[1][5]).to eq("2026-03-09")
      expect(rows[1][6]).to eq("returned")
    end
  end

  describe "#export_categories" do
    let!(:major)  { create(:category, name: "PC機器") }
    let!(:medium) { create(:category, :medium, name: "ノートPC類", parent: major) }
    let!(:minor)  { create(:category, :minor, name: "ThinkPad", parent: medium) }

    subject(:csv_string) { service.export_categories(Category.minor.includes(parent: :parent)) }

    it "UTF-8 BOMで始まる" do
      expect(csv_string).to start_with(bom)
    end

    it "正しいヘッダー行を含む（3カラム）" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      expect(rows[0]).to eq(%w[大分類名 中分類名 小分類名])
    end

    it "3カラム形式で階層を出力する" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      expect(rows[1]).to eq(["PC機器", "ノートPC類", "ThinkPad"])
    end
  end

  describe "#export_users" do
    let!(:user) do
      create(:user,
        name: "山田花子",
        email: "hanako@example.com",
        role: :admin
      )
    end

    subject(:csv_string) { service.export_users(User.all) }

    it "UTF-8 BOMで始まる" do
      expect(csv_string).to start_with(bom)
    end

    it "正しいヘッダー行を含む" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      expect(rows[0]).to eq(%w[名前 メールアドレス ロール 登録日])
    end

    it "ユーザーデータを正しく出力する" do
      rows = CSV.parse(csv_string.sub(bom, ""))
      expect(rows[1][0]).to eq("山田花子")
      expect(rows[1][1]).to eq("hanako@example.com")
      expect(rows[1][2]).to eq("admin")
    end

    it "パスワードハッシュを含まない" do
      expect(csv_string).not_to include("encrypted_password")
      expect(csv_string).not_to include(user.encrypted_password)
    end
  end
end
