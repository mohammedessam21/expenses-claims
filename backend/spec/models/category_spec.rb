require "rails_helper"

RSpec.describe Category do
  it "is valid with the factory defaults" do
    expect(build(:category)).to be_valid
  end

  it "requires both names" do
    category = build(:category, name_en: "", name_ar: "")

    expect(category).not_to be_valid
    expect(category.errors.full_messages).to include("English name can't be blank", "Arabic name can't be blank")
  end

  it "requires a positive whole-number limit" do
    expect(errors_for(build(:category, limit_halalas: 0), :limit_halalas)).to include("must be greater than 0")
    expect(errors_for(build(:category, limit_halalas: 10.5), :limit_halalas)).to include("must be an integer")
    expect(errors_for(build(:category, limit_halalas: "abc"), :limit_halalas)).to include("is not a number")
  end

  it "rejects a limit larger than the database integer column can hold" do
    expect(errors_for(build(:category, limit_halalas: 2_147_483_648), :limit_halalas)).to include("must be less than or equal to 2147483647")
  end
end
