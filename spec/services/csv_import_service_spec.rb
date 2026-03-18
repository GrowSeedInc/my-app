require "rails_helper"
require "csv"

RSpec.describe CsvImportService do
  let(:service) { described_class.new }

  def csv_content(headers, rows)
    CSV.generate(encoding: "UTF-8") do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end

  def mock_file(content, filename: "test.csv", content_type: "text/csv")
    file = StringIO.new(content)
    file.define_singleton_method(:original_filename) { filename }
    file.define_singleton_method(:content_type) { content_type }
    file
  end

  # ─── csv_file? ──────────────────────────────────────────────────────────────

  describe "#csv_file?" do
    it "text/csv の場合 true を返す" do
      expect(service.csv_file?(mock_file("x", content_type: "text/csv"))).to be true
    end

    it ".csv 拡張子かつ application/octet-stream の場合 true を返す" do
      expect(service.csv_file?(mock_file("x", filename: "data.csv", content_type: "application/octet-stream"))).to be true
    end

    it ".xlsx ファイルの場合 false を返す" do
      f = mock_file("x", filename: "data.xlsx",
                         content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      expect(service.csv_file?(f)).to be false
    end
  end

  # ─── import_categories ──────────────────────────────────────────────────────

  describe "#import_categories" do
    context "正常データ（3カラム）" do
      let(:content) do
        csv_content(%w[大分類名 中分類名 小分類名], [
          ["PC機器", "ノートPC類", "ThinkPad"],
          ["ネットワーク機器", "スイッチ類", "L2スイッチ"]
        ])
      end

      it "大分類・中分類・小分類の3階層を登録する" do
        expect { service.import_categories(mock_file(content)) }.to change(Category, :count).by(6)
      end

      it "success: true を返す" do
        result = service.import_categories(mock_file(content))
        expect(result[:success]).to be true
        expect(result[:count]).to eq 2
        expect(result[:errors]).to be_empty
      end

      it "大分類を major レベルで登録する" do
        service.import_categories(mock_file(content))
        expect(Category.major.find_by(name: "PC機器")).to be_present
      end

      it "小分類を正しい親に紐付けて登録する" do
        service.import_categories(mock_file(content))
        major  = Category.major.find_by(name: "PC機器")
        medium = Category.medium.find_by(name: "ノートPC類", parent_id: major.id)
        minor  = Category.minor.find_by(name: "ThinkPad", parent_id: medium.id)
        expect(minor).to be_present
      end
    end

    context "既存カテゴリと重複している場合（idempotent）" do
      let!(:existing_major)  { create(:category, name: "PC機器") }
      let!(:existing_medium) { create(:category, :medium, name: "ノートPC類", parent: existing_major) }
      let!(:existing_minor)  { create(:category, :minor, name: "ThinkPad", parent: existing_medium) }
      let(:content) do
        csv_content(%w[大分類名 中分類名 小分類名], [["PC機器", "ノートPC類", "ThinkPad"]])
      end

      it "エラーなく成功する（find_or_create）" do
        result = service.import_categories(mock_file(content))
        expect(result[:success]).to be true
      end

      it "新たなカテゴリを作成しない" do
        expect { service.import_categories(mock_file(content)) }.not_to change(Category, :count)
      end
    end

    context "中分類名が空の場合" do
      let(:content) { csv_content(%w[大分類名 中分類名 小分類名], [["PC機器", "", "ThinkPad"]]) }

      it "success: false を返す" do
        expect(service.import_categories(mock_file(content))[:success]).to be false
      end

      it "カテゴリを登録しない" do
        expect { service.import_categories(mock_file(content)) }.not_to change(Category, :count)
      end
    end

    context "小分類名が空の場合" do
      let(:content) { csv_content(%w[大分類名 中分類名 小分類名], [["PC機器", "ノートPC類", ""]]) }

      it "success: false を返す" do
        expect(service.import_categories(mock_file(content))[:success]).to be false
      end

      it "カテゴリを登録しない" do
        expect { service.import_categories(mock_file(content)) }.not_to change(Category, :count)
      end
    end

    context "大分類名が空の場合" do
      let(:content) { csv_content(%w[大分類名 中分類名 小分類名], [["", "ノートPC類", "ThinkPad"]]) }

      it "success: false を返す" do
        expect(service.import_categories(mock_file(content))[:success]).to be false
      end
    end
  end

  # ─── import_users ───────────────────────────────────────────────────────────

  describe "#import_users" do
    context "正常データ" do
      let(:content) do
        csv_content(
          %w[名前 メールアドレス ロール],
          [["田中太郎", "tanaka@example.com", "admin"],
           ["山田花子", "yamada@example.com", "member"]]
        )
      end

      it "ユーザーを登録する" do
        expect { service.import_users(mock_file(content)) }.to change(User, :count).by(2)
      end

      it "success: true を返す" do
        result = service.import_users(mock_file(content))
        expect(result[:success]).to be true
        expect(result[:count]).to eq 2
      end

      it "初期パスワード password123 で認証できる" do
        service.import_users(mock_file(content))
        user = User.find_by(email: "tanaka@example.com")
        expect(user.valid_password?("password123")).to be true
      end

      it "ロールを正しく設定する" do
        service.import_users(mock_file(content))
        expect(User.find_by(email: "tanaka@example.com").role).to eq "admin"
        expect(User.find_by(email: "yamada@example.com").role).to eq "member"
      end
    end

    context "ロールが省略された場合" do
      let(:content) do
        csv_content(%w[名前 メールアドレス ロール], [["田中太郎", "tanaka@example.com", ""]])
      end

      it "member ロールで登録する" do
        service.import_users(mock_file(content))
        expect(User.find_by(email: "tanaka@example.com").role).to eq "member"
      end
    end

    context "既存メールアドレスと重複している場合" do
      before { create(:user, email: "tanaka@example.com") }
      let(:content) do
        csv_content(%w[名前 メールアドレス ロール], [["田中太郎", "tanaka@example.com", "member"]])
      end

      it "全件ロールバックする" do
        expect { service.import_users(mock_file(content)) }.not_to change(User, :count)
      end
    end

    context "メールアドレス形式が不正な場合" do
      let(:content) do
        csv_content(%w[名前 メールアドレス ロール], [["田中太郎", "invalid-email", "member"]])
      end

      it "success: false を返す" do
        result = service.import_users(mock_file(content))
        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
      end
    end

    context "CSV 内でメールが重複している場合" do
      let(:content) do
        csv_content(
          %w[名前 メールアドレス ロール],
          [["田中太郎", "dup@example.com", "member"],
           ["田中二郎", "dup@example.com", "member"]]
        )
      end

      it "エラーを返して全ロールバックする" do
        result = service.import_users(mock_file(content))
        expect(result[:success]).to be false
        expect(User.count).to eq 0
      end
    end
  end

  # ─── import_equipments ──────────────────────────────────────────────────────

  describe "#import_equipments" do
    let!(:major)    { create(:category, name: "PC機器") }
    let!(:medium)   { create(:category, :medium, name: "ノートPC類", parent: major) }
    let!(:category) { create(:category, :minor, name: "ThinkPad", parent: medium) }

    context "正常データ" do
      let(:content) do
        csv_content(
          %w[備品名 管理番号 大分類名 中分類名 小分類名 ステータス 総数 在庫警告閾値 説明],
          [["ノートPC", "EQ-001", "PC機器", "ノートPC類", "ThinkPad", "available", "5", "2", "テスト用PC"],
           ["プロジェクター", "EQ-002", "", "", "", "available", "3", "1", ""]]
        )
      end

      it "備品を登録する" do
        expect { service.import_equipments(mock_file(content)) }.to change(Equipment, :count).by(2)
      end

      it "success: true を返す" do
        result = service.import_equipments(mock_file(content))
        expect(result[:success]).to be true
        expect(result[:count]).to eq 2
      end

      it "available_count を total_count と同値で登録する" do
        service.import_equipments(mock_file(content))
        eq = Equipment.find_by(management_number: "EQ-001")
        expect(eq.available_count).to eq eq.total_count
      end

      it "カテゴリを正しく紐付ける" do
        service.import_equipments(mock_file(content))
        expect(Equipment.find_by(management_number: "EQ-001").category).to eq category
      end

      it "カテゴリ列が全て空の場合 nil で登録する" do
        service.import_equipments(mock_file(content))
        expect(Equipment.find_by(management_number: "EQ-002").category).to be_nil
      end
    end

    context "小分類が存在しない場合" do
      let(:content) do
        csv_content(
          %w[備品名 管理番号 大分類名 中分類名 小分類名 ステータス 総数 在庫警告閾値 説明],
          [["ノートPC", "EQ-001", "PC機器", "ノートPC類", "存在しない小分類", "available", "5", "1", ""]]
        )
      end

      it "エラーを返す" do
        result = service.import_equipments(mock_file(content))
        expect(result[:success]).to be false
        expect(result[:errors].first[:message]).to include("存在しません")
      end
    end

    context "管理番号が既存と重複している場合" do
      before { create(:equipment, management_number: "EQ-001") }
      let(:content) do
        csv_content(
          %w[備品名 管理番号 大分類名 中分類名 小分類名 ステータス 総数 在庫警告閾値 説明],
          [["ノートPC", "EQ-001", "", "", "", "available", "5", "1", ""]]
        )
      end

      it "全件ロールバックする" do
        expect { service.import_equipments(mock_file(content)) }.not_to change(Equipment, :count)
      end
    end

    context "CSV 内で管理番号が重複している場合" do
      let(:content) do
        csv_content(
          %w[備品名 管理番号 大分類名 中分類名 小分類名 ステータス 総数 在庫警告閾値 説明],
          [["ノートPC", "EQ-001", "", "", "", "available", "5", "1", ""],
           ["ノートPC2", "EQ-001", "", "", "", "available", "3", "1", ""]]
        )
      end

      it "エラーを返す" do
        result = service.import_equipments(mock_file(content))
        expect(result[:success]).to be false
      end
    end

    context "必須項目（備品名・管理番号・総数）が欠損している場合" do
      let(:content) do
        csv_content(
          %w[備品名 管理番号 大分類名 中分類名 小分類名 ステータス 総数 在庫警告閾値 説明],
          [["", "EQ-001", "", "", "", "available", "", "1", ""]]
        )
      end

      it "複数のエラーを返す" do
        result = service.import_equipments(mock_file(content))
        expect(result[:success]).to be false
        expect(result[:errors].size).to be >= 2
      end
    end

    context "不正なステータス値の場合" do
      let(:content) do
        csv_content(
          %w[備品名 管理番号 大分類名 中分類名 小分類名 ステータス 総数 在庫警告閾値 説明],
          [["ノートPC", "EQ-001", "", "", "", "unknown_status", "5", "1", ""]]
        )
      end

      it "エラーを返す" do
        result = service.import_equipments(mock_file(content))
        expect(result[:success]).to be false
        expect(result[:errors].first[:message]).to include("ステータス")
      end
    end
  end

  # ─── import_loans ───────────────────────────────────────────────────────────

  describe "#import_loans" do
    let!(:category)  { create(:category, :minor, name: "PC機器") }
    let!(:equipment) { create(:equipment, management_number: "EQ-001", total_count: 5, available_count: 5, category: category) }
    let!(:user)      { create(:user, email: "tanaka@example.com") }

    context "正常データ（active + returned）" do
      let(:content) do
        csv_content(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["EQ-001", "tanaka@example.com", "active",   "2026-03-01", "2026-03-10", ""],
           ["EQ-001", "tanaka@example.com", "returned", "2026-02-01", "2026-02-10", "2026-02-09"]]
        )
      end

      it "貸出履歴を登録する" do
        expect { service.import_loans(mock_file(content)) }.to change(Loan, :count).by(2)
      end

      it "success: true を返す" do
        result = service.import_loans(mock_file(content))
        expect(result[:success]).to be true
        expect(result[:count]).to eq 2
      end

      it "active 1件分だけ在庫数を減らして再計算する" do
        service.import_loans(mock_file(content))
        # active=1 → available_count = 5 - 1 = 4
        expect(equipment.reload.available_count).to eq 4
      end

      it "recalculated_count を返す" do
        result = service.import_loans(mock_file(content))
        expect(result[:recalculated_count]).to be > 0
      end

      it "warnings が空である" do
        result = service.import_loans(mock_file(content))
        expect(result[:warnings]).to be_empty
      end
    end

    context "存在しない管理番号の場合" do
      let(:content) do
        csv_content(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["XX-999", "tanaka@example.com", "active", "2026-03-01", "2026-03-10", ""]]
        )
      end

      it "エラーを返して全ロールバックする" do
        result = service.import_loans(mock_file(content))
        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
        expect(Loan.count).to eq 0
      end
    end

    context "存在しないメールアドレスの場合" do
      let(:content) do
        csv_content(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["EQ-001", "noexist@example.com", "active", "2026-03-01", "2026-03-10", ""]]
        )
      end

      it "エラーを返す" do
        result = service.import_loans(mock_file(content))
        expect(result[:success]).to be false
      end
    end

    context "returned ステータスで実返却日が空の場合" do
      let(:content) do
        csv_content(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["EQ-001", "tanaka@example.com", "returned", "2026-03-01", "2026-03-10", ""]]
        )
      end

      it "実返却日必須エラーを返す" do
        result = service.import_loans(mock_file(content))
        expect(result[:success]).to be false
        expect(result[:errors].first[:message]).to include("実返却日")
      end
    end

    context "不正な日付形式の場合" do
      let(:content) do
        csv_content(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["EQ-001", "tanaka@example.com", "active", "2026/03/01", "2026-03-10", ""]]
        )
      end

      it "日付形式エラーを返す" do
        result = service.import_loans(mock_file(content))
        expect(result[:success]).to be false
        expect(result[:errors].first[:message]).to include("日付形式")
      end
    end

    context "不正なステータス値の場合" do
      let(:content) do
        csv_content(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["EQ-001", "tanaka@example.com", "invalid", "2026-03-01", "2026-03-10", ""]]
        )
      end

      it "エラーを返す" do
        result = service.import_loans(mock_file(content))
        expect(result[:success]).to be false
      end
    end

    context "active 貸出数が total_count を超える場合（在庫不整合）" do
      let!(:equipment2) { create(:equipment, management_number: "EQ-002", total_count: 1, available_count: 1) }
      let!(:user2)      { create(:user, email: "yamada@example.com") }
      let(:content) do
        csv_content(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["EQ-002", "tanaka@example.com", "active", "2026-03-01", "2026-03-10", ""],
           ["EQ-002", "yamada@example.com", "active", "2026-03-01", "2026-03-10", ""]]
        )
      end

      it "登録自体は成功する" do
        result = service.import_loans(mock_file(content))
        expect(result[:success]).to be true
      end

      it "warnings に不整合情報を含める" do
        result = service.import_loans(mock_file(content))
        expect(result[:warnings]).not_to be_empty
      end

      it "available_count を 0 にキャップする" do
        service.import_loans(mock_file(content))
        expect(equipment2.reload.available_count).to eq 0
      end
    end
  end
end
