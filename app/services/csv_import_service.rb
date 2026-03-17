require "csv"

class CsvImportService
  VALID_EQUIPMENT_STATUSES = %w[available in_use repair disposed].freeze
  VALID_LOAN_STATUSES      = %w[pending_approval active returned overdue].freeze
  VALID_USER_ROLES         = %w[admin member].freeze

  # @param file [ActionDispatch::Http::UploadedFile]
  # @return [Hash] { success: Boolean, count: Integer, errors: Array, message: String }
  def import_categories(file)
    rows = parse_csv(file)
    errors = []

    rows.each_with_index do |row, idx|
      row_num     = idx + 2
      major_name  = row["大分類名"]&.strip
      medium_name = row["中分類名"]&.strip
      minor_name  = row["小分類名"]&.strip

      errors << { row: row_num, message: "大分類名は必須です" } if major_name.blank?
      errors << { row: row_num, message: "中分類名は必須です" } if medium_name.blank?
      errors << { row: row_num, message: "小分類名は必須です" } if minor_name.blank?
    end

    return error_result(errors) if errors.any?

    count = 0
    save_errors = []
    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, idx|
        major_name  = row["大分類名"].strip
        medium_name = row["中分類名"].strip
        minor_name  = row["小分類名"].strip

        major  = Category.find_or_create_by!(name: major_name, level: :major, parent_id: nil)
        medium = Category.find_or_create_by!(name: medium_name, level: :medium, parent_id: major.id)
        Category.find_or_create_by!(name: minor_name, level: :minor, parent_id: medium.id)
        count += 1
      rescue ActiveRecord::RecordInvalid => e
        save_errors << { row: idx + 2, message: e.message }
        raise ActiveRecord::Rollback
      end
    end

    return error_result(save_errors) if save_errors.any?

    { success: true, count: count, errors: [], message: "#{count}件のカテゴリ階層を登録しました" }
  end

  # @param file [ActionDispatch::Http::UploadedFile]
  # @return [Hash] { success: Boolean, count: Integer, errors: Array, message: String }
  def import_users(file)
    rows = parse_csv(file)
    errors = []
    emails_in_csv = []

    rows.each_with_index do |row, idx|
      row_num = idx + 2
      name  = row["名前"]&.strip
      email = row["メールアドレス"]&.strip
      role  = row["ロール"]&.strip.presence || "member"

      errors << { row: row_num, message: "名前は必須です" } if name.blank?

      if email.blank?
        errors << { row: row_num, message: "メールアドレスは必須です" }
      else
        unless email.match?(URI::MailTo::EMAIL_REGEXP)
          errors << { row: row_num, message: "メールアドレス '#{email}' の形式が不正です" }
        end

        if emails_in_csv.include?(email)
          errors << { row: row_num, message: "メールアドレス '#{email}' がCSV内で重複しています" }
        end

        if User.exists?(email: email)
          errors << { row: row_num, message: "メールアドレス '#{email}' は既に登録されています" }
        end
      end

      unless VALID_USER_ROLES.include?(role)
        errors << { row: row_num, message: "ロール '#{role}' は無効です（admin または member を指定してください）" }
      end

      emails_in_csv << email if email.present?
    end

    return error_result(errors) if errors.any?

    count = 0
    save_errors = []
    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, idx|
        result = UserService.new.create(
          name:     row["名前"].strip,
          email:    row["メールアドレス"].strip,
          password: "password123",
          role:     row["ロール"]&.strip.presence || "member"
        )
        unless result[:success]
          save_errors << { row: idx + 2, message: result[:user]&.errors&.full_messages&.join(", ") || "登録に失敗しました" }
          raise ActiveRecord::Rollback
        end
        count += 1
      end
    end

    return error_result(save_errors) if save_errors.any?

    { success: true, count: count, errors: [], message: "#{count}件のユーザーを登録しました（初期パスワード: password123）" }
  end

  # @param file [ActionDispatch::Http::UploadedFile]
  # @return [Hash] { success: Boolean, count: Integer, errors: Array, message: String }
  def import_equipments(file)
    rows = parse_csv(file)
    errors = []
    management_numbers_in_csv = []

    rows.each_with_index do |row, idx|
      row_num           = idx + 2
      name              = row["備品名"]&.strip
      management_number = row["管理番号"]&.strip
      major_name        = row["大分類名"]&.strip
      medium_name       = row["中分類名"]&.strip
      minor_name        = row["小分類名"]&.strip
      status            = row["ステータス"]&.strip.presence || "available"
      total_count       = row["総数"]&.strip

      errors << { row: row_num, message: "備品名は必須です" } if name.blank?

      if management_number.blank?
        errors << { row: row_num, message: "管理番号は必須です" }
      else
        if management_numbers_in_csv.include?(management_number)
          errors << { row: row_num, message: "管理番号 '#{management_number}' がCSV内で重複しています" }
        end

        if Equipment.exists?(management_number: management_number)
          errors << { row: row_num, message: "管理番号 '#{management_number}' は既に登録されています" }
        end
      end

      category_specified = major_name.present? || medium_name.present? || minor_name.present?
      if category_specified && !find_minor_category(major_name, medium_name, minor_name)
        errors << { row: row_num, message: "カテゴリ '#{major_name} > #{medium_name} > #{minor_name}' が存在しません" }
      end

      unless VALID_EQUIPMENT_STATUSES.include?(status)
        errors << { row: row_num, message: "ステータス '#{status}' は無効です" }
      end

      if total_count.blank?
        errors << { row: row_num, message: "総数は必須です" }
      elsif total_count !~ /\A\d+\z/ || total_count.to_i < 0
        errors << { row: row_num, message: "総数は0以上の整数を入力してください" }
      end

      management_numbers_in_csv << management_number if management_number.present?
    end

    return error_result(errors) if errors.any?

    count = 0
    save_errors = []
    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, idx|
        major_name    = row["大分類名"]&.strip
        medium_name   = row["中分類名"]&.strip
        minor_name    = row["小分類名"]&.strip
        low_stock_raw = row["在庫警告閾値"]&.strip
        low_stock     = low_stock_raw.present? ? low_stock_raw.to_i : 1
        category_specified = major_name.present? || medium_name.present? || minor_name.present?
        category      = category_specified ? find_minor_category(major_name, medium_name, minor_name) : nil

        result = EquipmentService.new.create(
          name:                row["備品名"].strip,
          management_number:   row["管理番号"].strip,
          total_count:         row["総数"].strip.to_i,
          available_count:     row["総数"].strip.to_i,
          category_id:         category&.id,
          status:              row["ステータス"]&.strip.presence || "available",
          low_stock_threshold: low_stock,
          description:         row["説明"]&.strip
        )
        unless result[:success]
          save_errors << { row: idx + 2, message: result[:equipment]&.errors&.full_messages&.join(", ") || "登録に失敗しました" }
          raise ActiveRecord::Rollback
        end
        count += 1
      end
    end

    return error_result(save_errors) if save_errors.any?

    { success: true, count: count, errors: [], message: "#{count}件の備品を登録しました" }
  end

  # @param file [ActionDispatch::Http::UploadedFile]
  # @return [Hash] { success: Boolean, count: Integer, errors: Array,
  #                  recalculated_count: Integer, warnings: Array, message: String }
  def import_loans(file)
    rows = parse_csv(file)
    errors = []

    rows.each_with_index do |row, idx|
      row_num                  = idx + 2
      management_number        = row["管理番号"]&.strip
      user_email               = row["メールアドレス"]&.strip
      status                   = row["ステータス"]&.strip
      start_date_str           = row["開始日"]&.strip
      expected_return_date_str = row["予定返却日"]&.strip
      actual_return_date_str   = row["実返却日"]&.strip

      if management_number.blank?
        errors << { row: row_num, message: "管理番号は必須です" }
      elsif !Equipment.kept.exists?(management_number: management_number)
        errors << { row: row_num, message: "管理番号 '#{management_number}' の備品が存在しません" }
      end

      if user_email.blank?
        errors << { row: row_num, message: "メールアドレスは必須です" }
      elsif !User.exists?(email: user_email)
        errors << { row: row_num, message: "メールアドレス '#{user_email}' のユーザーが存在しません" }
      end

      if status.blank?
        errors << { row: row_num, message: "ステータスは必須です" }
      elsif !VALID_LOAN_STATUSES.include?(status)
        errors << { row: row_num, message: "ステータス '#{status}' は無効です" }
      end

      if start_date_str.blank?
        errors << { row: row_num, message: "開始日は必須です" }
      else
        validate_date(start_date_str, "開始日", row_num, errors)
      end

      if expected_return_date_str.blank?
        errors << { row: row_num, message: "予定返却日は必須です" }
      else
        validate_date(expected_return_date_str, "予定返却日", row_num, errors)
      end

      if status == "returned" && actual_return_date_str.blank?
        errors << { row: row_num, message: "返却済みステータスの場合、実返却日は必須です" }
      end

      validate_date(actual_return_date_str, "実返却日", row_num, errors) if actual_return_date_str.present?
    end

    return loans_error_result(errors) if errors.any?

    count = 0
    save_errors = []
    recalc_result = nil

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, idx|
        equipment = Equipment.kept.find_by!(management_number: row["管理番号"].strip)
        user      = User.find_by!(email: row["メールアドレス"].strip)

        loan = Loan.new(
          equipment:            equipment,
          user:                 user,
          status:               row["ステータス"].strip,
          start_date:           Date.parse(row["開始日"].strip),
          expected_return_date: Date.parse(row["予定返却日"].strip),
          actual_return_date:   row["実返却日"]&.strip.present? ? Date.parse(row["実返却日"].strip) : nil
        )

        unless loan.save
          save_errors << { row: idx + 2, message: loan.errors.full_messages.join(", ") }
          raise ActiveRecord::Rollback
        end

        count += 1
      end

      recalc_result = recalculate_available_counts
    end

    return loans_error_result(save_errors) if save_errors.any?

    {
      success:             true,
      count:               count,
      errors:              [],
      recalculated_count:  recalc_result[:updated],
      warnings:            recalc_result[:warnings],
      message:             "#{count}件の貸出履歴を登録し、#{recalc_result[:updated]}件の備品の在庫数を再計算しました"
    }
  end

  # @param file [ActionDispatch::Http::UploadedFile]
  # @return [Boolean]
  def csv_file?(file)
    return false unless file.respond_to?(:content_type) && file.respond_to?(:original_filename)

    content_type_ok = file.content_type.in?(%w[text/csv text/plain application/csv application/octet-stream])
    extension_ok    = File.extname(file.original_filename.to_s).casecmp(".csv").zero?
    content_type_ok || extension_ok
  end

  private

  def parse_csv(file)
    file.rewind if file.respond_to?(:rewind)
    content = file.respond_to?(:read) ? file.read : file
    content = content.force_encoding("UTF-8")
    content = content.sub("\xEF\xBB\xBF", "")  # Remove BOM
    CSV.parse(content, headers: true).map(&:to_h)
  rescue CSV::MalformedCSVError => e
    raise ArgumentError, "CSVの形式が不正です: #{e.message}"
  end

  def validate_date(date_str, field_name, row_num, errors)
    Date.strptime(date_str, "%Y-%m-%d")
  rescue ArgumentError, Date::Error
    errors << { row: row_num, message: "#{field_name} '#{date_str}' の日付形式が不正です（YYYY-MM-DD）" }
  end

  # 貸出履歴インポート後に各備品の available_count を再計算する
  # available_count = total_count - (active + overdue の貸出数)
  # @return [Hash] { updated: Integer, warnings: Array<String> }
  def recalculate_available_counts
    updated  = 0
    warnings = []

    active_counts = Loan.where(status: %w[active overdue])
                        .group(:equipment_id)
                        .count

    Equipment.kept.find_each do |equipment|
      active_loan_count = active_counts[equipment.id] || 0
      new_available     = equipment.total_count - active_loan_count

      if active_loan_count > equipment.total_count
        warnings << "#{equipment.name}（#{equipment.management_number}）: " \
                    "貸出中/延滞中の貸出数（#{active_loan_count}件）が総数（#{equipment.total_count}件）を超えています"
      end

      equipment.update_columns(available_count: [ new_available, 0 ].max)
      updated += 1
    end

    { updated: updated, warnings: warnings }
  end

  def find_minor_category(major_name, medium_name, minor_name)
    return nil if major_name.blank? || medium_name.blank? || minor_name.blank?

    major  = Category.major.find_by(name: major_name)
    return nil unless major

    medium = Category.medium.find_by(name: medium_name, parent_id: major.id)
    return nil unless medium

    Category.minor.find_by(name: minor_name, parent_id: medium.id)
  end

  def error_result(errors)
    { success: false, count: 0, errors: errors, message: "バリデーションエラーがあります" }
  end

  def loans_error_result(errors)
    { success: false, count: 0, errors: errors, recalculated_count: 0, warnings: [], message: "バリデーションエラーがあります" }
  end
end
