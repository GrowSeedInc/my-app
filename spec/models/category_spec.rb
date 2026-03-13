require "rails_helper"

RSpec.describe Category, type: :model do
  describe "バリデーション" do
    it "名前があれば有効である" do
      category = build(:category)
      expect(category).to be_valid
    end

    it "名前が必須である" do
      category = build(:category, name: nil)
      expect(category).not_to be_valid
      expect(category.errors[:name]).to be_present
    end

    it "名前が空文字の場合は無効である" do
      category = build(:category, name: "")
      expect(category).not_to be_valid
      expect(category.errors[:name]).to be_present
    end

    it "名前が一意である" do
      create(:category, name: "PC機器")
      duplicate = build(:category, name: "PC機器")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "名前が異なれば複数のカテゴリを作成できる" do
      create(:category, name: "PC機器")
      another = build(:category, name: "家具")
      expect(another).to be_valid
    end
  end
end
