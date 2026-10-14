require "rails_helper"

RSpec.describe "Employee claims API" do
  let(:company) { create(:company) }
  let(:employee) { create(:user, company: company, name: "Sara") }
  let(:coworker) { create(:user, company: company) }
  let(:approver) { create(:approver, company: company, name: "Omar") }
  let(:category) { create(:category, company: company, name_en: "Transport", name_ar: "مواصلات", limit_halalas: 50_000) }

  let(:other_company) { create(:company) }
  let(:other_employee) { create(:user, company: other_company) }
  let(:other_category) { create(:category, company: other_company) }

  def submit_as(user, cat: category, amount: 15_000)
    ClaimWorkflow.submit(employee: user, category: cat, attributes: { amount_halalas: amount, description: "Taxi", spent_on: "2026-10-01" })
  end

  def claim_params(overrides = {})
    { claim: { category_id: category.id, amount_halalas: 15_000, description: "Taxi to client", spent_on: "2026-10-01" }.merge(overrides) }
  end

  describe "GET /api/v1/categories" do
    it "lists only the active categories of the user's company" do
      category
      create(:category, company: company, name_en: "Old", active: false)
      other_category

      get "/api/v1/categories", headers: auth_headers(employee)

      expect(response).to have_http_status(:ok)
      expect(json["categories"]).to eq([
        { "id" => category.id, "name_en" => "Transport", "name_ar" => "مواصلات", "limit_halalas" => 50_000, "active" => true }
      ])
    end

    it "requires authentication" do
      get "/api/v1/categories"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/claims" do
    it "returns only the current user's own claims" do
      own = submit_as(employee)
      submit_as(coworker)
      submit_as(other_employee, cat: other_category)

      get "/api/v1/claims", headers: auth_headers(employee)

      expect(response).to have_http_status(:ok)
      expect(json["claims"].map { |c| c["id"] }).to eq([own.id])
      expect(json["claims"].first).to include(
        "reference_code" => own.reference_code, "status" => "submitted", "amount_halalas" => 15_000, "spent_on" => "2026-10-01"
      )
      expect(json["claims"].first["category"]).to include("name_en" => "Transport", "name_ar" => "مواصلات")
    end
  end

  describe "GET /api/v1/claims/:id" do
    it "returns the claim with its event timeline and available actions" do
      claim = submit_as(employee)
      ClaimWorkflow.new(claim, approver).start_review
      ClaimWorkflow.new(claim, approver).return_claim("Wrong amount")

      get "/api/v1/claims/#{claim.id}", headers: auth_headers(employee)

      expect(response).to have_http_status(:ok)
      expect(json["claim"]).to include("status" => "returned", "limit_halalas_at_submission" => 50_000, "available_actions" => %w[resubmit withdraw])
      expect(json["claim"]["reviewer"]).to eq("id" => approver.id, "name" => "Omar")
      expect(json["claim"]["events"].map { |e| [e["action"], e["from_status"], e["to_status"], e["actor"]["name"], e["comment"]] }).to eq([
        ["submit", nil, "submitted", "Sara", nil],
        ["start_review", "submitted", "under_review", "Omar", nil],
        ["return", "under_review", "returned", "Omar", "Wrong amount"]
      ])
      expect(json["claim"]["events"].first["created_at"]).to be_present
    end

    it "returns 404 for a coworker's claim" do
      claim = submit_as(coworker)

      get "/api/v1/claims/#{claim.id}", headers: auth_headers(employee)

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Claim not found")
    end

    it "returns 404 for another company's claim" do
      claim = submit_as(other_employee, cat: other_category)

      get "/api/v1/claims/#{claim.id}", headers: auth_headers(employee)

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Claim not found")
    end
  end

  describe "POST /api/v1/claims" do
    it "creates a submitted claim and ignores protected fields" do
      params = claim_params(
        status: "approved", employee_id: coworker.id, company_id: other_company.id, reviewer_id: approver.id,
        reference_code: "CLM-999999", limit_halalas_at_submission: 999_999
      )

      post "/api/v1/claims", params: params, headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:created)
      claim = Claim.find(json["claim"]["id"])
      expect(claim).to have_attributes(
        status: "submitted", employee: employee, company: company, reviewer: nil, limit_halalas_at_submission: 50_000
      )
      expect(claim.reference_code).not_to eq("CLM-999999")
      expect(claim.events.pluck(:action)).to eq(["submit"])
    end

    it "returns 422 with a descriptive message when the amount exceeds the limit" do
      post "/api/v1/claims", params: claim_params(amount_halalas: 50_001), headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "Amount exceeds the category limit of 500.00 SAR")
    end

    it "returns 422 for a fractional amount" do
      post "/api/v1/claims", params: claim_params(amount_halalas: 150.5), headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "Amount must be an integer")
    end

    it "returns 422 for a zero amount" do
      post "/api/v1/claims", params: claim_params(amount_halalas: 0), headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "Amount must be greater than 0")
    end

    it "returns 404 for a category of another company" do
      post "/api/v1/claims", params: claim_params(category_id: other_category.id), headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Category not found")
      expect(Claim.count).to eq(0)
    end

    it "returns 404 for an inactive category" do
      inactive = create(:category, company: company, active: false)

      post "/api/v1/claims", params: claim_params(category_id: inactive.id), headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 400 when the claim parameters are missing" do
      post "/api/v1/claims", params: {}, headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]).to be_present
    end
  end

  describe "POST /api/v1/claims/:id/resubmit" do
    let(:claim) do
      submit_as(employee).tap do |c|
        ClaimWorkflow.new(c, approver).start_review
        ClaimWorkflow.new(c, approver).return_claim("Fix it")
      end
    end

    it "updates amount and description and moves the claim back to submitted" do
      post "/api/v1/claims/#{claim.id}/resubmit",
           params: { claim: { amount_halalas: 12_000, description: "Fixed", status: "approved" } },
           headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["claim"]).to include("status" => "submitted", "amount_halalas" => 12_000, "description" => "Fixed")
    end

    it "resubmits without a body, keeping the amount and description" do
      post "/api/v1/claims/#{claim.id}/resubmit", headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["claim"]).to include("status" => "submitted", "amount_halalas" => 15_000, "description" => "Taxi")
      expect(json["claim"]["reviewer"]).to be_nil
      expect(claim.events.reload.last).to have_attributes(
        action: "resubmit", actor: employee, from_status: "returned", to_status: "submitted"
      )
    end

    it "resubmits with an empty claim object" do
      post "/api/v1/claims/#{claim.id}/resubmit", params: { claim: {} }, headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["claim"]).to include("status" => "submitted", "amount_halalas" => 15_000, "description" => "Taxi")
    end

    it "ignores protected fields when resubmitting" do
      post "/api/v1/claims/#{claim.id}/resubmit",
           params: { claim: { status: "approved", reviewer_id: approver.id, limit_halalas_at_submission: 999_999 } },
           headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:ok)
      expect(claim.reload).to have_attributes(status: "submitted", reviewer: nil, limit_halalas_at_submission: 50_000)
    end

    it "returns 404 when a coworker resubmits without a body" do
      post "/api/v1/claims/#{claim.id}/resubmit", headers: auth_headers(coworker), as: :json

      expect(response).to have_http_status(:not_found)
      expect(claim.reload.status).to eq("returned")
    end

    it "returns 422 when the claim is not returned" do
      submitted = submit_as(employee)

      post "/api/v1/claims/#{submitted.id}/resubmit", params: { claim: { description: "x" } }, headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "Cannot resubmit a claim that is submitted")
    end

    it "returns 422 when the edited amount exceeds the limit at submission" do
      post "/api/v1/claims/#{claim.id}/resubmit", params: { claim: { amount_halalas: 50_001 } }, headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "Amount exceeds the category limit of 500.00 SAR")
    end
  end

  describe "POST /api/v1/claims/:id/withdraw" do
    it "withdraws the user's submitted claim" do
      claim = submit_as(employee)

      post "/api/v1/claims/#{claim.id}/withdraw", headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["claim"]["status"]).to eq("withdrawn")
    end

    it "returns 404 for a coworker's claim" do
      claim = submit_as(coworker)

      post "/api/v1/claims/#{claim.id}/withdraw", headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:not_found)
      expect(claim.reload.status).to eq("submitted")
    end
  end
end
