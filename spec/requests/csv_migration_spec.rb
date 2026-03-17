require "rails_helper"
require "csv"

RSpec.describe "CSV移行フロー", type: :request do
  let!(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }

  def csv_data(headers, rows = [])
    CSV.generate(encoding: "UTF-8") do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end

  def upload_csv(content, filename: "test.csv")
    Rack::Test::UploadedFile.new(StringIO.new(content), "text/csv", false, original_filename: filename)
  end

  # ─── 備品 CSV エクスポート ───────────────────────────────────────────────────

  describe "GET /equipments/export_csv" do
    let!(:equipment) { create(:equipment) }

    context "認証済みの場合" do
      before { sign_in member }

      it "Content-Type: text/csv のレスポンスを返す" do
        get export_csv_equipments_path
        expect(response.content_type).to include("text/csv")
      end

      it "200を返す" do
        get export_csv_equipments_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "管理者の場合" do
      before { sign_in admin }

      it "Content-Type: text/csv のレスポンスを返す" do
        get export_csv_equipments_path
        expect(response.content_type).to include("text/csv")
      end
    end

    context "未認証の場合" do
      it "ログイン画面へリダイレクト" do
        get export_csv_equipments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ─── 備品 CSV インポート ─────────────────────────────────────────────────────

  describe "POST /equipments/import_csv" do
    let!(:category) { create(:category, :minor, name: "PC機器") }

    context "管理者の場合" do
      before { sign_in admin }

      it "正常データで備品を登録しリダイレクトする" do
        csv = csv_data(
          %w[備品名 管理番号 カテゴリ名 ステータス 総数 在庫警告閾値 説明],
          [["ノートPC", "EQ-001", "PC機器", "available", "3", "1", ""]]
        )
        expect {
          post import_csv_equipments_path, params: { file: upload_csv(csv) }
        }.to change(Equipment, :count).by(1)
        expect(response).to redirect_to(equipments_path)
      end

      it "バリデーションエラー時はリダイレクトする" do
        csv = csv_data(
          %w[備品名 管理番号 カテゴリ名 ステータス 総数 在庫警告閾値 説明],
          [["", "EQ-001", "PC機器", "available", "3", "1", ""]]
        )
        post import_csv_equipments_path, params: { file: upload_csv(csv) }
        expect(response).to redirect_to(equipments_path)
      end

      it "ファイル未選択時はリダイレクトする" do
        post import_csv_equipments_path
        expect(response).to redirect_to(equipments_path)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        csv = csv_data(%w[備品名 管理番号 カテゴリ名 ステータス 総数 在庫警告閾値 説明], [])
        post import_csv_equipments_path, params: { file: upload_csv(csv) }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── 備品テンプレートダウンロード ───────────────────────────────────────────

  describe "GET /equipments/import_template" do
    context "管理者の場合" do
      before { sign_in admin }

      it "CSV ファイルをダウンロードする" do
        get import_template_equipments_path
        expect(response.content_type).to include("text/csv")
        expect(response).to have_http_status(:ok)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get import_template_equipments_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── 貸出 CSV エクスポート ───────────────────────────────────────────────────

  describe "GET /loans/export_csv" do
    before { create(:loan, user: member) }

    context "管理者の場合" do
      before { sign_in admin }

      it "Content-Type: text/csv を返す" do
        get export_csv_loans_path
        expect(response.content_type).to include("text/csv")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "Content-Type: text/csv を返す" do
        get export_csv_loans_path
        expect(response.content_type).to include("text/csv")
      end

      it "他ユーザーの貸出データが含まれない" do
        other     = create(:user)
        other_eq  = create(:equipment, name: "他人の備品", management_number: "OTH-001")
        create(:loan, user: other, equipment: other_eq)
        get export_csv_loans_path
        expect(response.body).not_to include("他人の備品")
      end
    end
  end

  # ─── カテゴリ CSV エクスポート ───────────────────────────────────────────────

  describe "GET /admin/category_majors/export_csv" do
    before { create(:category, :minor) }

    context "管理者の場合" do
      before { sign_in admin }

      it "Content-Type: text/csv を返す" do
        get export_csv_admin_category_majors_path
        expect(response.content_type).to include("text/csv")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get export_csv_admin_category_majors_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── カテゴリ CSV インポート ──────────────────────────────────────────────────

  describe "POST /admin/category_majors/import_csv" do
    context "管理者の場合" do
      before { sign_in admin }

      it "正常データでカテゴリを登録しリダイレクトする" do
        csv = csv_data(%w[大分類名 中分類名 小分類名], [["PC機器", "ノートPC", "ThinkPad"]])
        expect {
          post import_csv_admin_category_majors_path, params: { file: upload_csv(csv) }
        }.to change(Category, :count).by(3)
        expect(response).to redirect_to(admin_category_majors_path)
      end

      it "バリデーションエラー時はリダイレクトする" do
        csv = csv_data(%w[大分類名 中分類名 小分類名], [["", "", ""]])
        post import_csv_admin_category_majors_path, params: { file: upload_csv(csv) }
        expect(response).to redirect_to(admin_category_majors_path)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        csv = csv_data(%w[大分類名 中分類名 小分類名], [])
        post import_csv_admin_category_majors_path, params: { file: upload_csv(csv) }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── ユーザー CSV エクスポート ───────────────────────────────────────────────

  describe "GET /admin/users/export_csv" do
    context "管理者の場合" do
      before { sign_in admin }

      it "Content-Type: text/csv を返す" do
        get export_csv_admin_users_path
        expect(response.content_type).to include("text/csv")
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get export_csv_admin_users_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── ユーザー CSV インポート ──────────────────────────────────────────────────

  describe "POST /admin/users/import_csv" do
    context "管理者の場合" do
      before { sign_in admin }

      it "正常データでユーザーを登録しリダイレクトする" do
        csv = csv_data(%w[名前 メールアドレス ロール], [["田中太郎", "tanaka@example.com", "member"]])
        expect {
          post import_csv_admin_users_path, params: { file: upload_csv(csv) }
        }.to change(User, :count).by(1)
        expect(response).to redirect_to(admin_users_path)
      end

      it "バリデーションエラー時はリダイレクトする" do
        csv = csv_data(%w[名前 メールアドレス ロール], [["", "invalid", "member"]])
        post import_csv_admin_users_path, params: { file: upload_csv(csv) }
        expect(response).to redirect_to(admin_users_path)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        csv = csv_data(%w[名前 メールアドレス ロール], [])
        post import_csv_admin_users_path, params: { file: upload_csv(csv) }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── 貸出履歴 CSV インポート ──────────────────────────────────────────────────

  describe "POST /admin/loans/import_csv" do
    let!(:equipment_for_loan) { create(:equipment, management_number: "EQ-001") }
    let!(:loan_user)          { create(:user, email: "loan_user@example.com") }

    context "管理者の場合" do
      before { sign_in admin }

      it "正常データで貸出履歴を登録しリダイレクトする" do
        csv = csv_data(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["EQ-001", "loan_user@example.com", "returned", "2026-03-01", "2026-03-10", "2026-03-09"]]
        )
        expect {
          post import_csv_admin_loans_path, params: { file: upload_csv(csv) }
        }.to change(Loan, :count).by(1)
        expect(response).to redirect_to(loans_path)
      end

      it "バリデーションエラー時はリダイレクトする" do
        csv = csv_data(
          %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
          [["XX-999", "loan_user@example.com", "active", "2026-03-01", "2026-03-10", ""]]
        )
        post import_csv_admin_loans_path, params: { file: upload_csv(csv) }
        expect(response).to redirect_to(loans_path)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        csv = csv_data(%w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日], [])
        post import_csv_admin_loans_path, params: { file: upload_csv(csv) }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ─── 移行フロー統合テスト ────────────────────────────────────────────────────

  describe "移行フロー: カテゴリ → ユーザー → 備品 → 貸出履歴" do
    before { sign_in admin }

    it "順序インポート後に在庫数が正確である" do
      # Step 1: カテゴリインポート（大分類名・中分類名・小分類名）
      post import_csv_admin_category_majors_path,
           params: { file: upload_csv(csv_data(%w[大分類名 中分類名 小分類名], [["PC機器", "ノートPC", "ThinkPad"]])) }
      expect(Category.find_by(name: "PC機器")).to be_present

      # Step 2: ユーザーインポート
      post import_csv_admin_users_path,
           params: { file: upload_csv(csv_data(%w[名前 メールアドレス ロール], [["田中太郎", "migration_user@example.com", "member"]])) }
      expect(User.find_by(email: "migration_user@example.com")).to be_present

      # Step 3: 備品インポート（total_count=5）
      post import_csv_equipments_path,
           params: { file: upload_csv(csv_data(
             %w[備品名 管理番号 カテゴリ名 ステータス 総数 在庫警告閾値 説明],
             [["ノートPC", "MIG-001", "PC機器", "available", "5", "1", ""]]
           )) }
      equipment = Equipment.find_by(management_number: "MIG-001")
      expect(equipment).to be_present
      expect(equipment.available_count).to eq 5

      # Step 4: 貸出履歴インポート（active 1件 + returned 1件）
      post import_csv_admin_loans_path,
           params: { file: upload_csv(csv_data(
             %w[管理番号 メールアドレス ステータス 開始日 予定返却日 実返却日],
             [["MIG-001", "migration_user@example.com", "active",   "2026-03-01", "2026-03-10", ""],
              ["MIG-001", "migration_user@example.com", "returned", "2026-02-01", "2026-02-10", "2026-02-09"]]
           )) }

      # active 1件 → available_count = 5 - 1 = 4
      expect(equipment.reload.available_count).to eq 4
    end
  end
end
