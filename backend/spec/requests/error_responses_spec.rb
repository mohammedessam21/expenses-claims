require "rails_helper"

RSpec.describe "Error responses" do
  it "returns JSON 404 for an unknown route" do
    get "/api/v1/nothing-here"

    expect(response).to have_http_status(:not_found)
    expect(json).to eq("error" => "Not found")
  end

  it "returns JSON 400 for a malformed JSON body" do
    post "/api/v1/auth/login", params: "{bad json", headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:bad_request)
    expect(json).to eq("error" => "Malformed JSON request body")
  end

  it "returns a generic JSON 500 without a stack trace for unexpected errors" do
    user = create(:user)
    allow(UserSerializer).to receive(:call).and_raise(RuntimeError, "boom")

    get "/api/v1/me", headers: auth_headers(user)

    expect(response).to have_http_status(:internal_server_error)
    expect(json).to eq("error" => "Internal server error")
  end
end
