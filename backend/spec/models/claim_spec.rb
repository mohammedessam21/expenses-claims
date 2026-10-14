require "rails_helper"

RSpec.describe Claim do
  it "generates a reference code from its id on create" do
    claim = create(:claim)

    expect(claim.reference_code).to eq(format("CLM-%06d", claim.id))
  end

  it "rejects an amount of zero" do
    expect(errors_for(build(:claim, amount_halalas: 0), :amount_halalas)).to include("must be greater than 0")
  end

  it "rejects fractional and non-numeric amounts" do
    expect(errors_for(build(:claim, amount_halalas: 100.5), :amount_halalas)).to include("must be an integer")
    expect(errors_for(build(:claim, amount_halalas: "12.50"), :amount_halalas)).to include("must be an integer")
    expect(errors_for(build(:claim, amount_halalas: "abc"), :amount_halalas)).to include("is not a number")
  end

  it "accepts an amount equal to the limit at submission" do
    expect(build(:claim, amount_halalas: 50_000, limit_halalas_at_submission: 50_000)).to be_valid
  end

  it "rejects an amount above the limit at submission with a SAR message" do
    claim = build(:claim, amount_halalas: 50_001, limit_halalas_at_submission: 50_000)

    expect(claim).not_to be_valid
    expect(claim.errors.full_messages).to include("Amount exceeds the category limit of 500.00 SAR")
  end

  it "rejects an unknown status" do
    expect(errors_for(build(:claim, status: "paid"), :status)).to include("is not included in the list")
  end

  it "requires a description and the spend date" do
    claim = build(:claim, description: "", spent_on: nil)

    expect(claim).not_to be_valid
    expect(claim.errors.full_messages).to include("Description can't be blank", "Date can't be blank")
  end

  it "requires the category to belong to the claim's company" do
    claim = build(:claim, category: create(:category))

    expect(errors_for(claim, :category)).to include("must belong to the same company")
  end
end
