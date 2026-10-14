seed_password = "Password123!"

seed_companies = [
  {
    name: "Acme Trading",
    domain: "acme.test",
    categories: [
      { name_en: "Transport", name_ar: "مواصلات", limit_halalas: 50_000 },
      { name_en: "Government Fees", name_ar: "رسوم حكومية", limit_halalas: 200_000 },
      { name_en: "Office Supplies", name_ar: "مستلزمات مكتبية", limit_halalas: 30_000 }
    ]
  },
  {
    name: "Globex Services",
    domain: "globex.test",
    categories: [
      { name_en: "Transport", name_ar: "مواصلات", limit_halalas: 40_000 },
      { name_en: "Meals", name_ar: "وجبات", limit_halalas: 25_000 },
      { name_en: "Training", name_ar: "تدريب", limit_halalas: 150_000 }
    ]
  }
]

seed_companies.each do |data|
  company = Company.find_or_create_by!(name: data[:name])

  { "employee" => "Employee", "approver" => "Approver" }.each do |role, title|
    User.find_or_create_by!(email: "#{role}@#{data[:domain]}") do |user|
      user.assign_attributes(company: company, role: role, name: "#{data[:name]} #{title}", password: seed_password)
    end
  end

  data[:categories].each do |attributes|
    company.categories.find_or_create_by!(name_en: attributes[:name_en]) do |category|
      category.assign_attributes(attributes)
    end
  end
end
