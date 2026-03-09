require "rails_helper"

RSpec.describe UserPolicy do
  let(:admin) { build(:user, :admin) }
  let(:member) { build(:user) }
  let(:user) { build(:user) }

  subject { described_class }

  permissions :index?, :show?, :new?, :create?, :edit?, :update?, :destroy? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, user)
    end

    it "一般ユーザーに拒否する" do
      expect(subject).not_to permit(member, user)
    end
  end
end
