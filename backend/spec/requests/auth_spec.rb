require "rails_helper"

RSpec.describe "Authentication" do
  let!(:user) { create(:user, email: "sara@example.com", password: "correct-pass", name: "Sara") }

  describe "POST /api/v1/auth/login" do
    it "returns a token and the user for valid credentials" do
      post "/api/v1/auth/login", params: { email: "SARA@example.com", password: "correct-pass" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["token"]).to be_present
      expect(json["user"]).to include("id" => user.id, "email" => "sara@example.com", "name" => "Sara", "role" => "employee")
      expect(json["user"]["company"]).to eq("id" => user.company.id, "name" => user.company.name)
      expect(json["user"]).not_to have_key("password_digest")
    end

    it "returns the same message for a wrong password and an unknown email" do
      post "/api/v1/auth/login", params: { email: "sara@example.com", password: "wrong" }, as: :json
      wrong_password = [response.status, json]

      post "/api/v1/auth/login", params: { email: "nobody@example.com", password: "correct-pass" }, as: :json
      unknown_email = [response.status, json]

      expect(wrong_password).to eq([401, { "error" => "Invalid email or password" }])
      expect(unknown_email).to eq(wrong_password)
    end

    it "rejects a missing password with the same message" do
      post "/api/v1/auth/login", params: { email: "sara@example.com" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json).to eq("error" => "Invalid email or password")
    end
  end

  describe "GET /api/v1/me" do
    it "returns the current user for a valid token" do
      post "/api/v1/auth/login", params: { email: "sara@example.com", password: "correct-pass" }, as: :json
      token = json["token"]

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(json["user"]).to include("id" => user.id, "role" => "employee")
    end

    it "returns 401 without a token" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json).to eq("error" => "Authentication required")
    end

    it "returns 401 for a tampered token" do
      get "/api/v1/me", headers: { "Authorization" => "Bearer not-a-real-token" }

      expect(response).to have_http_status(:unauthorized)
      expect(json).to eq("error" => "Authentication required")
    end

    it "returns 401 once the token has expired" do
      headers = auth_headers(user)

      travel 13.hours do
        get "/api/v1/me", headers: headers
      end

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
