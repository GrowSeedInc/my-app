require "rails_helper"

RSpec.describe Equipment, type: :model do
  describe "バリデーション" do
    it "必須項目がすべて揃っていれば有効である" do
      equipment = build(:equipment)
      expect(equipment).to be_valid
    end

    it "名称が必須である" do
      equipment = build(:equipment, name: nil)
      expect(equipment).not_to be_valid
      expect(equipment.errors[:name]).to be_present
    end

    it "管理番号が必須である" do
      equipment = build(:equipment, management_number: nil)
      expect(equipment).not_to be_valid
      expect(equipment.errors[:management_number]).to be_present
    end

    it "管理番号が一意である" do
      create(:equipment, management_number: "EQ-001")
      duplicate = build(:equipment, management_number: "EQ-001")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:management_number]).to be_present
    end

    it "管理番号が異なれば複数の備品を作成できる" do
      create(:equipment, management_number: "EQ-001")
      another = build(:equipment, management_number: "EQ-002")
      expect(another).to be_valid
    end

    it "総数が必須である" do
      equipment = build(:equipment, total_count: nil)
      expect(equipment).not_to be_valid
      expect(equipment.errors[:total_count]).to be_present
    end

    it "総数は0以上である" do
      equipment = build(:equipment, total_count: -1)
      expect(equipment).not_to be_valid
    end

    it "貸出可能数が必須である" do
      equipment = build(:equipment, available_count: nil)
      expect(equipment).not_to be_valid
      expect(equipment.errors[:available_count]).to be_present
    end

    it "貸出可能数は0以上である" do
      equipment = build(:equipment, available_count: -1)
      expect(equipment).not_to be_valid
    end
  end

  describe "ステータスenum" do
    it "デフォルトステータスはavailableである" do
      equipment = build(:equipment)
      expect(equipment.status).to eq("available")
    end

    it "availableステータスを設定できる" do
      equipment = build(:equipment, status: :available)
      expect(equipment).to be_available
    end

    it "in_useステータスを設定できる" do
      equipment = build(:equipment, status: :in_use)
      expect(equipment).to be_in_use
    end

    it "repairステータスを設定できる" do
      equipment = build(:equipment, status: :repair)
      expect(equipment).to be_repair
    end

    it "disposedステータスを設定できる" do
      equipment = build(:equipment, status: :disposed)
      expect(equipment).to be_disposed
    end
  end

  describe "論理削除（discard）" do
    it "discard後はdiscarded?がtrueになる" do
      equipment = create(:equipment)
      equipment.discard
      expect(equipment).to be_discarded
    end

    it "discardしていない備品はkeptスコープに含まれる" do
      equipment = create(:equipment)
      expect(Equipment.kept).to include(equipment)
    end

    it "discard済み備品はkeptスコープに含まれない" do
      equipment = create(:equipment)
      equipment.discard
      expect(Equipment.kept).not_to include(equipment)
    end
  end

  describe "アソシエーション" do
    it "カテゴリに属する" do
      category = create(:category, :minor)
      equipment = build(:equipment, category: category)
      expect(equipment.category).to eq(category)
    end

    it "カテゴリなしでも有効である" do
      equipment = build(:equipment, category: nil)
      expect(equipment).to be_valid
    end
  end

  describe "category_must_be_minor バリデーション" do
    it "小分類カテゴリを設定した場合は有効である" do
      minor = create(:category, :minor)
      equipment = build(:equipment, category: minor)
      expect(equipment).to be_valid
    end

    it "大分類カテゴリを設定した場合は無効である" do
      major = create(:category, level: :major)
      equipment = build(:equipment, category: major)
      expect(equipment).not_to be_valid
      expect(equipment.errors[:category]).to include("小分類（最下位カテゴリ）を選択してください")
    end

    it "中分類カテゴリを設定した場合は無効である" do
      medium = create(:category, :medium)
      equipment = build(:equipment, category: medium)
      expect(equipment).not_to be_valid
      expect(equipment.errors[:category]).to include("小分類（最下位カテゴリ）を選択してください")
    end

    it "カテゴリが nil の場合はスキップされる" do
      equipment = build(:equipment, category: nil)
      expect(equipment).to be_valid
    end
  end
end
