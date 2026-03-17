FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "カテゴリ#{n}" }
    level { :major }

    trait :medium do
      level { :medium }
      association :parent, factory: :category, strategy: :create
    end

    trait :minor do
      level { :minor }
      association :parent, factory: [:category, :medium], strategy: :create
    end
  end
end
