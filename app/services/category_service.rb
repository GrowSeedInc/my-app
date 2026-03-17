class CategoryService
  # @param name [String]
  # @param level [Symbol] :major | :medium | :minor
  # @param parent_id [String, nil] UUID。level=:major の場合は nil
  # @return [Hash] { success: Boolean, category: Category, error: Symbol, message: String }
  def create(name:, level: :major, parent_id: nil)
    category = Category.new(name: name, level: level, parent_id: parent_id)

    if category.save
      { success: true, category: category }
    else
      { success: false, category: category, error: :validation_failed, message: category.errors.full_messages.join(", ") }
    end
  end

  # @param category [Category]
  # @param params [Hash]
  # @return [Hash]
  def update(category:, params:)
    if category.update(params)
      { success: true, category: category }
    else
      { success: false, category: category, error: :validation_failed, message: category.errors.full_messages.join(", ") }
    end
  end

  # @param category [Category]
  # @return [Hash]
  def destroy(category:)
    if category.children.exists?
      return { success: false, error: :has_children, message: "このカテゴリには子カテゴリが登録されているため削除できません" }
    end

    if category.destroy
      { success: true }
    else
      { success: false, error: :has_equipments, message: "このカテゴリには備品が登録されているため削除できません" }
    end
  end
end
