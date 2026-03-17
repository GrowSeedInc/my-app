class UserPolicy < ApplicationPolicy
  def index?      = user.admin?
  def show?       = user.admin?
  def new?        = user.admin?
  def create?     = user.admin?
  def edit?       = user.admin?
  def update?     = user.admin?
  def destroy?    = user.admin?
  def export_csv? = user.admin?
  def import_csv? = user.admin?
end
