class OverdueCheckJob < ApplicationJob
  queue_as :default

  def perform
    overdue_loans = Loan.where(status: :active)
                        .where("expected_return_date < ?", Date.today)
                        .includes(:equipment, :user)

    overdue_loans.find_each do |loan|
      loan_service.mark_overdue(loan: loan)
      notification_service.send_overdue_alert(loan: loan)
    end
  end

  private

  def loan_service
    @loan_service ||= LoanService.new
  end

  def notification_service
    @notification_service ||= NotificationService.new
  end
end
