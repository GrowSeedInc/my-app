class MigrateCategoriesToHierarchy < ActiveRecord::Migration[8.1]
  def up
    # 全ての大分類（既存フラットカテゴリ）を対象に移行
    # migrated_from_flat=false の大分類のみ処理（再実行安全性のため）
    major_categories = Category.where(level: 0, migrated_from_flat: false)

    major_categories.each do |major|
      # 中分類を生成（level=1, parent=大分類, migrated_from_flat=true）
      medium = Category.new(
        name: major.name,
        level: :medium,
        parent_id: major.id,
        migrated_from_flat: true
      )
      medium.save!

      # 小分類を生成（level=2, parent=中分類, migrated_from_flat=true）
      minor = Category.new(
        name: major.name,
        level: :minor,
        parent_id: medium.id,
        migrated_from_flat: true
      )
      minor.save!

      # 当該大分類を参照していた備品を小分類に更新（バリデーションを回避するため update_all を使用）
      Equipment.where(category_id: major.id).update_all(category_id: minor.id)
    end

    # 移行後の検証:
    # カテゴリあり保持備品が全て小分類を参照していることを確認する
    minor_ids = Category.where(level: 2).select(:id)
    kept_with_category_count = Equipment.kept.where.not(category_id: nil).count
    migrated_count = Equipment.kept.where(category_id: minor_ids).count

    if kept_with_category_count != migrated_count
      raise "データ移行検証失敗: Equipment.kept のカテゴリあり #{kept_with_category_count} 件中 " \
            "#{migrated_count} 件のみが小分類を参照しています"
    end
  end

  def down
    # migrated_from_flat=true の小分類（level=2）を特定してロールバック
    migrated_minors = Category.where(migrated_from_flat: true, level: 2)

    migrated_minors.each do |minor|
      medium = minor.parent
      next unless medium&.migrated_from_flat?

      major = medium.parent
      next unless major

      # 小分類を参照していた備品を元の大分類に戻す
      Equipment.where(category_id: minor.id).update_all(category_id: major.id)
    end

    # 移行生成レコードを削除（FK 制約上、子→親の順で削除）
    Category.where(migrated_from_flat: true, level: 2).delete_all
    Category.where(migrated_from_flat: true, level: 1).delete_all
  end
end
