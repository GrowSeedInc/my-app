class EquipmentService
  # @param name [String]
  # @param management_number [String]
  # @param total_count [Integer]
  # @param available_count [Integer, nil]
  # @param description [String, nil]
  # @param category_id [String, nil]
  # @param status [Symbol]
  # @param low_stock_threshold [Integer]
  # @return [Hash] { success: Boolean, equipment: Equipment, error: Symbol, message: String }
  def create(name:, management_number:, total_count:, available_count: nil, description: nil, category_id: nil, status: :available, low_stock_threshold: 1)
    equipment = Equipment.new(
      name: name,
      management_number: management_number,
      total_count: total_count,
      available_count: available_count.nil? ? total_count : available_count,
      description: description,
      category_id: category_id,
      status: status,
      low_stock_threshold: low_stock_threshold
    )

    if equipment.save
      { success: true, equipment: equipment }
    else
      { success: false, equipment: equipment, error: :validation_failed, message: equipment.errors.full_messages.join(", ") }
    end
  end

  # @param equipment [Equipment]
  # @param params [Hash]
  # @return [Hash]
  def update(equipment:, params:)
    if equipment.update(params)
      { success: true, equipment: equipment }
    else
      { success: false, equipment: equipment, error: :validation_failed, message: equipment.errors.full_messages.join(", ") }
    end
  end

  # @param equipment [Equipment]
  # @return [Hash]
  def destroy(equipment:)
    if equipment.loans.where(status: [ :active, :overdue ]).exists?
      return { success: false, error: :has_active_loans, message: "貸出中のため削除できません" }
    end

    equipment.discard
    { success: true }
  end
end
