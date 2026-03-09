class NotificationService
  # 貸出確認メールを申請ユーザーに非同期送信する
  def send_loan_confirmation(loan:)
    LoanMailer.loan_confirmation(loan).deliver_later
  rescue => e
    Rails.logger.error("貸出確認メール送信失敗 loan_id=#{loan.id}: #{e.message}")
  end

  # 延滞アラートメールを管理者全員に非同期送信する
  def send_overdue_alert(loan:)
    LoanMailer.overdue_alert(loan).deliver_later
  rescue => e
    Rails.logger.error("延滞アラートメール送信失敗 loan_id=#{loan.id}: #{e.message}")
  end

  # 在庫不足アラートメールを管理者全員に非同期送信する
  def send_low_stock_alert(equipment:)
    LoanMailer.low_stock_alert(equipment).deliver_later
  rescue => e
    Rails.logger.error("在庫不足アラートメール送信失敗 equipment_id=#{equipment.id}: #{e.message}")
  end
end
