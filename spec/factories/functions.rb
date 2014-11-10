FactoryGirl.define do
  factory :function do
    sequence(:name) { |n| "function_name_#{n}" }
  end
end
