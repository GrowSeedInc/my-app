class Category < ApplicationRecord
  has_many :equipments, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
