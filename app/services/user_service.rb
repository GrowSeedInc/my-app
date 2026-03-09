class UserService
  def create(name:, email:, password:, role:)
    user = User.new(
      name: name,
      email: email,
      password: password,
      password_confirmation: password,
      role: role
    )
    if user.save
      { success: true, user: user }
    else
      { success: false, user: user, error: :validation_failed, message: user.errors.full_messages.join(", ") }
    end
  end

  def update(user:, params:)
    if user.update(params)
      { success: true, user: user }
    else
      { success: false, user: user, error: :validation_failed, message: user.errors.full_messages.join(", ") }
    end
  end

  def destroy(user:)
    if user.loans.where(status: %i[active overdue]).exists?
      return { success: false, error: :has_active_loans, message: "貸出中の備品があるため削除できません" }
    end
    user.destroy
    { success: true }
  rescue => e
    { success: false, error: :destroy_failed, message: e.message }
  end
end
