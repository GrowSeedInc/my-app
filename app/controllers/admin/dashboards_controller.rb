class Admin::DashboardsController < ApplicationController
  def show
    authorize :dashboard, :show?
    @summary       = inventory_service.dashboard_summary
    @overdue_loans = inventory_service.overdue_loans
  end

  private

  def inventory_service
    @inventory_service ||= InventoryService.new
  end
end
