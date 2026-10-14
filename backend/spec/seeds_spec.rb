require "rails_helper"

RSpec.describe "Seed data" do
  def load_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates two companies, each with one employee, one approver and three categories" do
    load_seeds

    expect(Company.count).to eq(2)
    Company.find_each do |company|
      expect(company.users.where(role: "employee").count).to eq(1)
      expect(company.users.where(role: "approver").count).to eq(1)
      expect(company.categories.count).to eq(3)
      expect(company.categories.pluck(:name_ar)).to all(be_present)
    end
  end

  it "creates users that can log in with the documented password" do
    load_seeds

    expect(User.find_by(email: "employee@acme.test").authenticate("Password123!")).to be_truthy
    expect(User.find_by(email: "approver@globex.test").authenticate("Password123!")).to be_truthy
  end

  it "can be run twice without duplicating data" do
    2.times { load_seeds }

    expect([Company.count, User.count, Category.count]).to eq([2, 4, 6])
  end

  it "does not overwrite existing passwords or approver changes to categories when run again" do
    load_seeds
    user = User.find_by(email: "employee@acme.test")
    user.update!(password: "Changed456!")
    transport = Company.find_by(name: "Acme Trading").categories.find_by(name_en: "Transport")
    transport.update!(limit_halalas: 12_345, active: false)

    load_seeds

    expect(user.reload.authenticate("Changed456!")).to be_truthy
    expect(transport.reload).to have_attributes(limit_halalas: 12_345, active: false)
    expect([Company.count, User.count, Category.count]).to eq([2, 4, 6])
  end
end
