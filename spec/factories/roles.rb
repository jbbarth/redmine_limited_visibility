FactoryGirl.define do
  factory :role do
    sequence(:name) { |n| "role_name_#{n}" }
    assignable true
    builtin 0
    issues_visibility 'default'
    limit_visibility false
  end
end
