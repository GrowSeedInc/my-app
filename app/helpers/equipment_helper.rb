module EquipmentHelper
  # 備品のカテゴリーを「大分類 > 中分類 > 小分類」形式の文字列で返す。
  # カテゴリー未設定の場合は "—" を返す。
  # NOTE: equipment は category: { parent: :parent } を eager_load 済みであること。
  def equipment_category_path(equipment)
    equipment.category&.hierarchy_path || "—"
  end
end
