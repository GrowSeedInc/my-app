require "rails_helper"

RSpec.describe EquipmentPolicy do
  let(:admin) { build(:user, :admin) }
  let(:member) { build(:user) }
  let(:equipment) { build(:equipment) }

  subject { described_class }

  permissions :index?, :show? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, equipment)
    end

    it "一般ユーザーに許可する" do
      expect(subject).to permit(member, equipment)
    end
  end

  permissions :new?, :create?, :edit?, :update?, :destroy? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, equipment)
    end

    it "一般ユーザーに拒否する" do
      expect(subject).not_to permit(member, equipment)
    end
  end

  permissions :export_csv? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, equipment)
    end

    it "一般ユーザーに許可する" do
      expect(subject).to permit(member, equipment)
    end
  end

  permissions :import_csv? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, equipment)
    end

    it "一般ユーザーに拒否する" do
      expect(subject).not_to permit(member, equipment)
    end
  end
end
