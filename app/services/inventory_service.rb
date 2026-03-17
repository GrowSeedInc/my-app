class InventoryService
  # 備品ステータスを変更する
  # @param equipment [Equipment]
  # @param status [Symbol, String]
  # @return [Hash] { success: Boolean, equipment: Equipment, error: Symbol, message: String }
  def change_status(equipment:, status:)
    if equipment.update(status: status)
      { success: true, equipment: equipment }
    else
      { success: false, equipment: equipment, error: :validation_failed, message: equipment.errors.full_messages.join(", ") }
    end
  rescue ArgumentError => e
    { success: false, equipment: equipment, error: :invalid_status, message: e.message }
  end

  # 大分類単位の在庫サマリーを返す
  # @return [Array<Hash>] 大分類別集計の配列
  def dashboard_summary
    all_equipments = Equipment.kept.includes(category: { parent: :parent })
    equipments_by_major = all_equipments.group_by { |e| e.category&.parent&.parent }
    equipments_by_major.map do |major, equipments|
      total     = equipments.sum(&:total_count)
      available = equipments.sum(&:available_count)
      {
        category:        major,
        total_count:     total,
        available_count: available,
        in_use_count:    total - available,
        equipment_count: equipments.count
      }
    end.sort_by { |s| s[:category]&.name.to_s }
  end

  # 延滞中の貸出一覧を返す（返却予定日昇順）
  # @return [ActiveRecord::Relation]
  def overdue_loans
    Loan.includes(:equipment, :user).where(status: :overdue).order(:expected_return_date)
  end
end
