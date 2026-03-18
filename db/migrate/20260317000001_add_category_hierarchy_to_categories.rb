class AddCategoryHierarchyToCategories < ActiveRecord::Migration[8.1]
  def up
    add_column :categories, :parent_id, :uuid, null: true
    add_column :categories, :level, :integer, null: false, default: 0
    add_column :categories, :migrated_from_flat, :boolean, null: false, default: false

    add_foreign_key :categories, :categories, column: :parent_id

    remove_index :categories, name: "index_categories_on_name"

    add_index :categories, :name,
              unique: true,
              where: "parent_id IS NULL",
              name: "idx_categories_name_root"

    add_index :categories, %i[parent_id name],
              unique: true,
              where: "parent_id IS NOT NULL",
              name: "idx_categories_name_scoped"

    add_index :categories, :parent_id, name: "idx_categories_parent_id"
  end

  def down
    remove_index :categories, name: "idx_categories_parent_id"
    remove_index :categories, name: "idx_categories_name_scoped"
    remove_index :categories, name: "idx_categories_name_root"

    remove_foreign_key :categories, column: :parent_id

    add_index :categories, :name, unique: true

    remove_column :categories, :migrated_from_flat
    remove_column :categories, :level
    remove_column :categories, :parent_id
  end
end
