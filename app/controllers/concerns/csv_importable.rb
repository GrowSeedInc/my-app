module CsvImportable
  extend ActiveSupport::Concern

  private

  # CSV ファイルのバリデーションを行い、問題があれば redirect してその path を返す。
  # 問題なければ nil を返す。
  #
  # @param file [ActionDispatch::Http::UploadedFile, nil]
  # @param redirect_path [String]
  # @return [String, nil] リダイレクト先 path（エラー時）または nil（正常時）
  def validate_csv_upload(file, redirect_path)
    unless file.present?
      redirect_to redirect_path, alert: "ファイルを選択してください"
      return redirect_path
    end
    if file.size > 5.megabytes
      redirect_to redirect_path, alert: "ファイルサイズは5MB以下にしてください"
      return redirect_path
    end
    unless CsvImportService.new.csv_file?(file)
      redirect_to redirect_path, alert: "CSVファイルを選択してください"
      return redirect_path
    end
    nil
  end

  # インポート結果を処理してリダイレクトする。
  #
  # @param result [Hash] CsvImportService が返す結果ハッシュ
  # @param redirect_path [String]
  # @param success_notice [String, nil] 成功時メッセージ（nil なら result[:message] を使用）
  def handle_csv_import_result(result, redirect_path, success_notice: nil)
    if result[:success]
      redirect_to redirect_path, notice: success_notice || result[:message]
    else
      errors = result[:errors]
      flash[:import_errors] = errors.first(50)
      flash[:import_errors_truncated] = errors.size - 50 if errors.size > 50
      redirect_to redirect_path, alert: result[:message]
    end
  end
end
