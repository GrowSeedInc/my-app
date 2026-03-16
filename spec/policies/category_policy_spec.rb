require "rails_helper"

RSpec.describe CategoryPolicy do
  let(:admin)  { build(:user, :admin) }
  let(:member) { build(:user) }
  let(:category) { build(:category) }

  subject { described_class }

  permissions :index?, :new?, :create?, :edit?, :update?, :destroy? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, category)
    end

    it "一般ユーザーに拒否する" do
      expect(subject).not_to permit(member, category)
    end
  end

  permissions :export_csv?, :import_csv? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, category)
    end

    it "一般ユーザーに拒否する" do
      expect(subject).not_to permit(member, category)
    end
  end
end
