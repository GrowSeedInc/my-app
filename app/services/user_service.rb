class UserService
  # @return [ServiceResult]
  def create(name:, email:, password:, role:)
    user = User.new(
      name: name,
      email: email,
      password: password,
      password_confirmation: password,
      role: role
    )
    if user.save
      ServiceResult.ok(user: user)
    else
      ServiceResult.err(error: :validation_failed, message: user.errors.full_messages.join(", "), user: user)
    end
  end

  # @return [ServiceResult]
  def update(user:, params:)
    if user.update(params)
      ServiceResult.ok(user: user)
    else
      ServiceResult.err(error: :validation_failed, message: user.errors.full_messages.join(", "), user: user)
    end
  end

  # @return [ServiceResult]
  def destroy(user:)
    if user.loans.active_or_overdue.exists?
      return ServiceResult.err(error: :has_active_loans, message: "貸出中の備品があるため削除できません")
    end
    user.destroy
    ServiceResult.ok
  rescue => e
    ServiceResult.err(error: :destroy_failed, message: e.message)
  end
end
