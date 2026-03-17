require "rails_helper"

RSpec.describe LoanPolicy do
  let(:admin) { build(:user, :admin) }
  let(:member) { build(:user) }
  let(:other_member) { build(:user) }

  subject { described_class }

  permissions :index?, :new?, :create? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, build(:loan, user: member))
    end

    it "一般ユーザーに許可する" do
      expect(subject).to permit(member, build(:loan, user: member))
    end
  end

  permissions :approve? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, build(:loan, user: member))
    end

    it "一般ユーザーに拒否する" do
      expect(subject).not_to permit(member, build(:loan, user: member))
    end
  end

  permissions :admin_entry? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, build(:loan, user: member))
    end

    it "一般ユーザーに拒否する" do
      expect(subject).not_to permit(member, build(:loan, user: member))
    end
  end

  permissions :export_csv? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, build(:loan, user: member))
    end

    it "一般ユーザーに許可する" do
      expect(subject).to permit(member, build(:loan, user: member))
    end
  end

  permissions :import_csv? do
    it "管理者に許可する" do
      expect(subject).to permit(admin, build(:loan, user: member))
    end

    it "一般ユーザーに拒否する" do
      expect(subject).not_to permit(member, build(:loan, user: member))
    end
  end
end
