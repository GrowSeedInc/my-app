class CategoryPolicy < ApplicationPolicy
  def index?      = user.admin?
  def new?        = user.admin?
  def create?     = user.admin?
  def edit?       = user.admin?
  def update?     = user.admin?
  def destroy?    = user.admin?
  def export_csv? = user.admin?
  def import_csv? = user.admin?
  def by_major?   = true  # 認証済みユーザーなら誰でも可（連動セレクト用）
  def by_medium?  = true  # 認証済みユーザーなら誰でも可（連動セレクト用）
end
