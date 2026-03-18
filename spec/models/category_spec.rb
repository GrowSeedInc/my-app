require "rails_helper"

RSpec.describe Category, type: :model do
  describe "バリデーション" do
    it "名前があれば有効である（大分類）" do
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

    it "大分類は同名が存在する場合は無効である（parent_id=nil スコープ）" do
      create(:category, name: "PC機器")
      duplicate = build(:category, name: "PC機器")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "名前が異なれば複数の大分類を作成できる" do
      create(:category, name: "PC機器")
      another = build(:category, name: "家具")
      expect(another).to be_valid
    end

    it "異なる親を持つ中分類は同名でも有効である" do
      major1 = create(:category, name: "PC機器")
      major2 = create(:category, name: "家具")
      create(:category, :medium, name: "ノートPC", parent: major1)
      duplicate = build(:category, :medium, name: "ノートPC", parent: major2)
      expect(duplicate).to be_valid
    end

    it "同じ親を持つ中分類は同名の場合無効である" do
      major = create(:category, name: "PC機器")
      create(:category, :medium, name: "ノートPC", parent: major)
      duplicate = build(:category, :medium, name: "ノートPC", parent: major)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    context "parent_id バリデーション" do
      it "中分類は parent_id が必須である" do
        category = build(:category, level: :medium, parent: nil)
        expect(category).not_to be_valid
        expect(category.errors[:parent_id]).to be_present
      end

      it "小分類は parent_id が必須である" do
        category = build(:category, level: :minor, parent: nil)
        expect(category).not_to be_valid
        expect(category.errors[:parent_id]).to be_present
      end

      it "大分類は parent_id なしでも有効である" do
        category = build(:category, level: :major, parent: nil)
        expect(category).to be_valid
      end
    end

    context "parent_level_consistency バリデーション" do
      it "中分類の親が major レベルであれば有効である" do
        major = create(:category, level: :major)
        medium = build(:category, :medium, parent: major)
        expect(medium).to be_valid
      end

      it "中分類の親が medium レベルの場合は無効である" do
        major = create(:category, level: :major)
        medium = create(:category, :medium, parent: major)
        invalid = build(:category, :medium, parent: medium)
        expect(invalid).not_to be_valid
        expect(invalid.errors[:parent_id]).to be_present
      end

      it "小分類の親が medium レベルであれば有効である" do
        medium = create(:category, :medium)
        minor = build(:category, level: :minor, parent: medium)
        expect(minor).to be_valid
      end

      it "小分類の親が major レベルの場合は無効である" do
        major = create(:category, level: :major)
        invalid = build(:category, level: :minor, parent: major)
        expect(invalid).not_to be_valid
        expect(invalid.errors[:parent_id]).to be_present
      end
    end
  end

  describe "level enum" do
    it "major（0）を設定できる" do
      category = build(:category, level: :major)
      expect(category).to be_major
    end

    it "medium（1）を設定できる" do
      major = create(:category)
      category = build(:category, :medium, parent: major)
      expect(category).to be_medium
    end

    it "minor（2）を設定できる" do
      category = build(:category, :minor)
      expect(category).to be_minor
    end
  end

  describe "スコープ" do
    let!(:major) { create(:category, level: :major) }
    let!(:medium) { create(:category, :medium, parent: major) }
    let!(:minor) { create(:category, :minor, parent: medium) }

    it "major スコープは大分類のみ返す" do
      expect(Category.major).to include(major)
      expect(Category.major).not_to include(medium, minor)
    end

    it "medium スコープは中分類のみ返す" do
      expect(Category.medium).to include(medium)
      expect(Category.medium).not_to include(major, minor)
    end

    it "minor スコープは小分類のみ返す" do
      expect(Category.minor).to include(minor)
      expect(Category.minor).not_to include(major, medium)
    end
  end

  describe "アソシエーション" do
    it "親カテゴリに属する" do
      major = create(:category)
      medium = create(:category, :medium, parent: major)
      expect(medium.parent).to eq(major)
    end

    it "子カテゴリを持てる" do
      major = create(:category)
      medium = create(:category, :medium, parent: major)
      expect(major.children).to include(medium)
    end

    it "子カテゴリが存在する場合は削除できない" do
      major = create(:category)
      create(:category, :medium, parent: major)
      major.destroy
      expect(major.errors[:base]).to be_present
      expect(Category.exists?(major.id)).to be true
    end
  end
end
