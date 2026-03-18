class CategoryService
  # @param name [String]
  # @param level [Symbol] :major | :medium | :minor
  # @param parent_id [String, nil] UUID。level=:major の場合は nil
  # @return [ServiceResult]
  def create(name:, level: :major, parent_id: nil)
    category = Category.new(name: name, level: level, parent_id: parent_id)

    if category.save
      ServiceResult.ok(category: category)
    else
      ServiceResult.err(error: :validation_failed, message: category.errors.full_messages.join(", "), category: category)
    end
  end

  # @param category [Category]
  # @param params [Hash]
  # @return [ServiceResult]
  def update(category:, params:)
    if category.update(params)
      ServiceResult.ok(category: category)
    else
      ServiceResult.err(error: :validation_failed, message: category.errors.full_messages.join(", "), category: category)
    end
  end

  # @param category [Category]
  # @return [ServiceResult]
  def destroy(category:)
    if category.children.exists?
      return ServiceResult.err(error: :has_children, message: "このカテゴリには子カテゴリが登録されているため削除できません")
    end

    if category.destroy
      ServiceResult.ok
    else
      ServiceResult.err(error: :has_equipments, message: "このカテゴリには備品が登録されているため削除できません")
    end
  end
end
