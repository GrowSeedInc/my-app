require "csv"

class CsvExportService
  # @param equipments [ActiveRecord::Relation<Equipment>]
  # @return [String] UTF-8 BOM 付き CSV 文字列
  def export_equipments(equipments)
    headers = %w[備品名 管理番号 カテゴリ ステータス 在庫数 貸出中数 説明]
    rows = equipments.includes(:category).map do |eq|
      [
        escape_formula(eq.name),
        eq.management_number,
        escape_formula(eq.category&.name.to_s),
        eq.status,
        eq.total_count,
        eq.total_count - eq.available_count,
        escape_formula(eq.description.to_s)
      ]
    end
    generate_csv(headers, rows)
  end

  # @param loans [ActiveRecord::Relation<Loan>]
  # @return [String] UTF-8 BOM 付き CSV 文字列
  def export_loans(loans)
    headers = %w[備品名 貸出者名 申請日 承認日 予定返却日 実返却日 ステータス]
    rows = loans.includes(:equipment, :user).map do |loan|
      [
        escape_formula(loan.equipment.name),
        escape_formula(loan.user.name.to_s),
        loan.created_at.to_date.to_s,
        loan.start_date.to_s,
        loan.expected_return_date.to_s,
        loan.actual_return_date.to_s,
        loan.status
      ]
    end
    generate_csv(headers, rows)
  end

  # @param categories [ActiveRecord::Relation<Category>]
  # @return [String] UTF-8 BOM 付き CSV 文字列
  def export_categories(categories)
    headers = %w[カテゴリ名]
    rows = categories.map { |c| [ escape_formula(c.name) ] }
    generate_csv(headers, rows)
  end

  # @param users [ActiveRecord::Relation<User>]
  # @return [String] UTF-8 BOM 付き CSV 文字列
  def export_users(users)
    headers = %w[名前 メールアドレス ロール 登録日]
    rows = users.map do |u|
      [ escape_formula(u.name.to_s), escape_formula(u.email), u.role, u.created_at.to_date.to_s ]
    end
    generate_csv(headers, rows)
  end

  private

  # CSVフォーミュラインジェクション対策: =, +, -, @ で始まる値に ' を付与する
  def escape_formula(value)
    str = value.to_s
    str.start_with?("=", "+", "-", "@") ? "'" + str : str
  end

  # @param headers [Array<String>]
  # @param rows [Array<Array>]
  # @return [String] UTF-8 BOM 付き CSV 文字列
  def generate_csv(headers, rows)
    bom = "\xEF\xBB\xBF"
    csv_body = CSV.generate(encoding: "UTF-8") do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
    bom + csv_body
  end
end
