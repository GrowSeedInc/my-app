require "rails_helper"

RSpec.describe User, type: :model do
  describe "Deviseモジュール" do
    it { is_expected.to respond_to(:email) }
    it { is_expected.to respond_to(:encrypted_password) }
    it { is_expected.to respond_to(:reset_password_token) }
  end

  describe "バリデーション" do
    it "emailが必須である" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it "emailが一意である" do
      create(:user, email: "test@example.com")
      duplicate = build(:user, email: "test@example.com")
      expect(duplicate).not_to be_valid
    end

    it "パスワードが必須である" do
      user = build(:user, password: nil)
      expect(user).not_to be_valid
    end

    it "パスワードが8文字未満の場合は無効である" do
      user = build(:user, password: "short1", password_confirmation: "short1")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "パスワードが8文字の場合は有効である" do
      user = build(:user, password: "valid123", password_confirmation: "valid123")
      expect(user).to be_valid
    end

    it "パスワードが8文字超の場合は有効である" do
      user = build(:user, password: "validpassword", password_confirmation: "validpassword")
      expect(user).to be_valid
    end
  end

  describe "role" do
    it "デフォルトのroleはmemberである" do
      user = build(:user)
      expect(user.role).to eq("member")
    end

    it "adminロールを設定できる" do
      user = build(:user, role: :admin)
      expect(user).to be_admin
    end

    it "memberロールを設定できる" do
      user = build(:user, role: :member)
      expect(user).to be_member
    end

    it "adminはmemberでない" do
      user = build(:user, role: :admin)
      expect(user).not_to be_member
    end
  end
end
