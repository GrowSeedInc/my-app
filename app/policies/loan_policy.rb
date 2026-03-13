class LoanPolicy < ApplicationPolicy
  def index?
    true
  end

  def new?
    true
  end

  def create?
    true
  end

  def approve?
    user.admin?
  end

  def return_loan?
    user.admin? || record.user == user
  end

  def admin_entry?
    user.admin?
  end
end
