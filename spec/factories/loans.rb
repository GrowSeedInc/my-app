FactoryBot.define do
  factory :loan do
    association :equipment
    association :user
    start_date { Date.today }
    expected_return_date { Date.today + 7 }
    actual_return_date { nil }
    status { :pending_approval }
  end
end
