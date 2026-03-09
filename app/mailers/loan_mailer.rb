class LoanMailer < ApplicationMailer
  # 貸出確認メール（申請ユーザー宛）
  def loan_confirmation(loan)
    @loan      = loan
    @user      = loan.user
    @equipment = loan.equipment
    mail(to: @user.email, subject: "【備品管理システム】貸出申請受付のご確認")
  end

  # 在庫不足アラート（管理者全員宛）
  def low_stock_alert(equipment)
    @equipment    = equipment
    admin_emails  = User.where(role: :admin).pluck(:email)
    mail(to: admin_emails, subject: "【備品管理システム】在庫不足アラート: #{equipment.name}")
  end

  # 延滞アラート（管理者全員宛）
  def overdue_alert(loan)
    @loan        = loan
    @equipment   = loan.equipment
    @user        = loan.user
    admin_emails = User.where(role: :admin).pluck(:email)
    mail(to: admin_emails, subject: "【備品管理システム】延滞アラート: #{loan.equipment.name}")
  end
end
