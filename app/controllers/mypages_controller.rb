class MypagesController < ApplicationController
  def show
    @active_loans = current_user.loans
                                .includes(:equipment)
                                .where(status: %i[active overdue])
                                .order(:expected_return_date)
    @past_loans   = current_user.loans
                                .includes(:equipment)
                                .where(status: :returned)
                                .order(actual_return_date: :desc)
  end
end
