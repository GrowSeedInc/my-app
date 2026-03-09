require "rails_helper"

RSpec.describe UserService do
  let(:service) { described_class.new }

  describe "#create" do
    context "有効なパラメータの場合" do
      let(:valid_params) do
        { name: "新規ユーザー", email: "newuser@example.com", password: "password123", role: :member }
      end

      it "ユーザーを作成して成功を返す" do
        result = service.create(**valid_params)
        expect(result[:success]).to be true
        expect(result[:user]).to be_persisted
      end

      it "指定したemailでユーザーが作成される" do
        service.create(**valid_params)
        expect(User.find_by(email: "newuser@example.com")).to be_present
      end

      it "管理者ロールでも作成できる" do
        result = service.create(name: "管理者", email: "admin2@example.com", password: "password123", role: :admin)
        expect(result[:success]).to be true
        expect(result[:user].role).to eq("admin")
      end
    end

    context "無効なパラメータの場合" do
      it "重複メールアドレスでエラーを返す" do
        create(:user, email: "dup@example.com")
        result = service.create(name: "重複", email: "dup@example.com", password: "password123", role: :member)
        expect(result[:success]).to be false
        expect(result[:user].errors[:email]).to be_present
      end

      it "パスワード不足でエラーを返す" do
        result = service.create(name: "短いPW", email: "short@example.com", password: "123", role: :member)
        expect(result[:success]).to be false
      end
    end
  end

  describe "#update" do
    let!(:user) { create(:user, name: "旧名前", email: "old@example.com", role: :member) }

    context "有効なパラメータの場合" do
      it "nameを更新して成功を返す" do
        result = service.update(user: user, params: { name: "新名前" })
        expect(result[:success]).to be true
        expect(user.reload.name).to eq("新名前")
      end

      it "roleをadminに変更できる" do
        result = service.update(user: user, params: { role: :admin })
        expect(result[:success]).to be true
        expect(user.reload.role).to eq("admin")
      end

      it "emailを更新できる" do
        result = service.update(user: user, params: { email: "new@example.com" })
        expect(result[:success]).to be true
        expect(user.reload.email).to eq("new@example.com")
      end
    end

    context "メールアドレスの重複がある場合" do
      it "エラーを返す" do
        create(:user, email: "taken@example.com")
        result = service.update(user: user, params: { email: "taken@example.com" })
        expect(result[:success]).to be false
      end
    end
  end

  describe "#destroy" do
    context "アクティブな貸出がないユーザーの場合" do
      let!(:user) { create(:user) }

      it "ユーザーを削除して成功を返す" do
        result = service.destroy(user: user)
        expect(result[:success]).to be true
        expect(User.find_by(id: user.id)).to be_nil
      end
    end

    context "アクティブな貸出があるユーザーの場合" do
      let!(:user) { create(:user) }
      let!(:equipment) { create(:equipment) }
      let!(:loan) { create(:loan, user: user, equipment: equipment, status: :active) }

      it "削除を拒否してエラーを返す" do
        result = service.destroy(user: user)
        expect(result[:success]).to be false
        expect(result[:message]).to be_present
        expect(User.find_by(id: user.id)).to be_present
      end
    end

    context "延滞中の貸出があるユーザーの場合" do
      let!(:user) { create(:user) }
      let!(:equipment) { create(:equipment) }
      let!(:loan) do
        create(:loan, user: user, equipment: equipment, status: :overdue,
               start_date: Date.today - 10, expected_return_date: Date.today - 3)
      end

      it "削除を拒否してエラーを返す" do
        result = service.destroy(user: user)
        expect(result[:success]).to be false
      end
    end
  end
end
