require "rails_helper"
require Rails.root.join("db/migrate/20260317000002_migrate_categories_to_hierarchy")

RSpec.describe MigrateCategoriesToHierarchy do
  let(:migration) { described_class.new }

  # 移行前状態のセットアップヘルパー:
  # equipment の category_must_be_minor バリデーションを回避して大分類を直接セット
  def create_equipment_with_major(major)
    eq = create(:equipment)
    eq.update_column(:category_id, major.id)
    eq
  end

  describe "#up" do
    let!(:major_a) { create(:category, name: "PCカテゴリ", level: :major) }
    let!(:major_b) { create(:category, name: "家具カテゴリ", level: :major) }
    let!(:equipment_a) { create_equipment_with_major(major_a) }
    let!(:equipment_b) { create_equipment_with_major(major_b) }
    let!(:equipment_no_cat) { create(:equipment, category: nil) }

    before { migration.up }

    it "各大分類に対して中分類が1件生成される（migrated_from_flat=true）" do
      [major_a, major_b].each do |major|
        mediums = Category.where(parent_id: major.id, level: 1, migrated_from_flat: true)
        expect(mediums.count).to eq(1), "大分類 #{major.name} の中分類が1件であること"
        expect(mediums.first.name).to eq(major.name)
      end
    end

    it "各大分類に対して小分類が1件生成される（migrated_from_flat=true）" do
      [major_a, major_b].each do |major|
        medium = Category.find_by(parent_id: major.id, level: 1)
        minors = Category.where(parent_id: medium.id, level: 2, migrated_from_flat: true)
        expect(minors.count).to eq(1), "大分類 #{major.name} の小分類が1件であること"
        expect(minors.first.name).to eq(major.name)
      end
    end

    it "備品の category_id が対応する小分類に更新される" do
      expect(equipment_a.reload.category.minor?).to be true
      expect(equipment_a.reload.category.name).to eq(major_a.name)
    end

    it "複数大分類にまたがる備品が各自の小分類を指す" do
      expect(equipment_b.reload.category.minor?).to be true
      expect(equipment_b.reload.category.name).to eq(major_b.name)
    end

    it "カテゴリなし備品の category_id は変更されない" do
      expect(equipment_no_cat.reload.category_id).to be_nil
    end

    it "全ての保持備品（category あり）が小分類を参照する" do
      kept_with_category = Equipment.kept.where.not(category_id: nil)
      kept_with_category.each do |eq|
        expect(eq.category.minor?).to be true
      end
    end

    it "大分類レコードはそのまま残る" do
      expect { major_a.reload }.not_to raise_error
      expect { major_b.reload }.not_to raise_error
      expect(major_a.reload.level).to eq("major")
    end
  end

  describe "#down" do
    let!(:major_a) { create(:category, name: "PCカテゴリ", level: :major) }
    let!(:major_b) { create(:category, name: "家具カテゴリ", level: :major) }
    let!(:equipment_a) { create_equipment_with_major(major_a) }
    let!(:equipment_b) { create_equipment_with_major(major_b) }

    before do
      migration.up
      migration.down
    end

    it "migrated_from_flat のカテゴリ（中分類・小分類）が削除される" do
      expect(Category.where(migrated_from_flat: true).count).to eq(0)
    end

    it "備品の category_id が元の大分類 ID に戻る" do
      expect(equipment_a.reload.category_id).to eq(major_a.id)
      expect(equipment_b.reload.category_id).to eq(major_b.id)
    end

    it "大分類レコードは削除されない" do
      expect { major_a.reload }.not_to raise_error
      expect { major_b.reload }.not_to raise_error
    end

    it "移行前後で大分類の件数が変わらない" do
      expect(Category.major.count).to eq(2)
    end
  end
end
