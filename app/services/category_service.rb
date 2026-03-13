class CategoryService
  # @param name [String]
  # @return [Hash] { success: Boolean, category: Category, error: Symbol, message: String }
  def create(name:)
    category = Category.new(name: name)

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
    if category.destroy
      { success: true }
    else
      { success: false, error: :has_equipments, message: "このカテゴリには備品が登録されているため削除できません" }
    end
  end
end
