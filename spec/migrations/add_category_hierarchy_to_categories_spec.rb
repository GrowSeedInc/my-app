require "rails_helper"

RSpec.describe "AddCategoryHierarchyToCategories マイグレーション" do
  let(:connection) { ActiveRecord::Base.connection }
  let(:columns) { connection.columns(:categories).index_by(&:name) }
  let(:indexes) { connection.indexes(:categories) }
  let(:index_names) { indexes.map(&:name) }

  describe "カラム追加" do
    it "parent_id カラムが存在する（UUID, nullable）" do
      expect(connection.column_exists?(:categories, :parent_id)).to be true
      expect(columns["parent_id"].null).to be true
    end

    it "level カラムが存在する（integer, NOT NULL, DEFAULT 0）" do
      expect(connection.column_exists?(:categories, :level, :integer)).to be true
      col = columns["level"]
      expect(col.null).to be false
      expect(col.default).to eq(0).or eq("0")
    end

    it "migrated_from_flat カラムが存在する（boolean, NOT NULL, DEFAULT false）" do
      expect(connection.column_exists?(:categories, :migrated_from_flat, :boolean)).to be true
      col = columns["migrated_from_flat"]
      expect(col.null).to be false
      expect(col.default).to eq(false).or eq("false")
    end
  end

  describe "インデックス" do
    it "旧グローバル一意インデックス index_categories_on_name が存在しない" do
      expect(index_names).not_to include("index_categories_on_name")
    end

    it "大分類用部分インデックス idx_categories_name_root が存在する（unique, WHERE parent_id IS NULL）" do
      idx = indexes.find { |i| i.name == "idx_categories_name_root" }
      expect(idx).not_to be_nil
      expect(idx.unique).to be true
      expect(idx.where).to include("parent_id IS NULL")
    end

    it "中小分類用部分インデックス idx_categories_name_scoped が存在する（unique, WHERE parent_id IS NOT NULL）" do
      idx = indexes.find { |i| i.name == "idx_categories_name_scoped" }
      expect(idx).not_to be_nil
      expect(idx.unique).to be true
      expect(idx.where).to include("parent_id IS NOT NULL")
    end

    it "子カテゴリ取得用インデックス idx_categories_parent_id が存在する" do
      expect(index_names).to include("idx_categories_parent_id")
    end
  end
end
