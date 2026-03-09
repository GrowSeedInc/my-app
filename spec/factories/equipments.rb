FactoryBot.define do
  factory :equipment do
    sequence(:name) { |n| "備品#{n}" }
    sequence(:management_number) { |n| "EQ-#{n.to_s.rjust(3, "0")}" }
    description { "備品の説明" }
    total_count { 5 }
    available_count { 5 }
    status { :available }
    low_stock_threshold { 1 }
    category { nil }
  end
end
