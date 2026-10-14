FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
  end

  factory :user do
    company
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    role { "employee" }
    password { "password123" }

    factory :approver do
      role { "approver" }
    end
  end

  factory :category do
    company
    name_en { "Transport" }
    name_ar { "مواصلات" }
    limit_halalas { 50_000 }
    active { true }
  end

  factory :claim do
    transient do
      owner { association :user }
    end

    employee { owner }
    company { employee.company }
    category { association :category, company: company }
    status { "submitted" }
    amount_halalas { 15_000 }
    limit_halalas_at_submission { category.limit_halalas }
    description { "Taxi to client meeting" }
    spent_on { Date.new(2026, 10, 1) }
  end
end
