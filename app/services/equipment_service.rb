class EquipmentService
  # @param name [String]
  # @param management_number [String]
  # @param total_count [Integer]
  # @param available_count [Integer, nil]
  # @param description [String, nil]
  # @param category_id [String, nil]
  # @param status [Symbol]
  # @param low_stock_threshold [Integer]
  # @return [ServiceResult]
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
      ServiceResult.ok(equipment: equipment)
    else
      ServiceResult.err(error: :validation_failed, message: equipment.errors.full_messages.join(", "), equipment: equipment)
    end
  end

  # @param equipment [Equipment]
  # @param params [Hash]
  # @return [ServiceResult]
  def update(equipment:, params:)
    if equipment.update(params)
      ServiceResult.ok(equipment: equipment)
    else
      ServiceResult.err(error: :validation_failed, message: equipment.errors.full_messages.join(", "), equipment: equipment)
    end
  end

  # @param equipment [Equipment]
  # @return [ServiceResult]
  def destroy(equipment:)
    if equipment.loans.active_or_overdue.exists?
      return ServiceResult.err(error: :has_active_loans, message: "貸出中のため削除できません")
    end

    equipment.discard
    ServiceResult.ok
  end
end
