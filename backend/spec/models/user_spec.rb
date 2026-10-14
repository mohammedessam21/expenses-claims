require "rails_helper"

RSpec.describe User do
  it "normalizes the email to lowercase without surrounding spaces" do
    user = create(:user, email: "  Sara@Example.COM ")

    expect(user.email).to eq("sara@example.com")
  end

  it "rejects an unknown role" do
    user = build(:user, role: "admin")

    expect(user).not_to be_valid
    expect(user.errors[:role]).to include("is not included in the list")
  end

  it "requires a unique email" do
    create(:user, email: "taken@example.com")

    expect(build(:user, email: "TAKEN@example.com")).not_to be_valid
  end

  it "authenticates with the correct password only" do
    user = create(:user, password: "secret-pass")

    expect(user.authenticate("secret-pass")).to eq(user)
    expect(user.authenticate("wrong")).to be(false)
  end
end
