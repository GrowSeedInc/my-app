class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { member: 0, admin: 1 }, default: :member

  has_many :loans

  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: :password_required?
end
