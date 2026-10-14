require "rails_helper"

RSpec.describe "Review claims API" do
  let(:company) { create(:company) }
  let(:employee) { create(:user, company: company) }
  let(:approver) { create(:approver, company: company) }
  let(:category) { create(:category, company: company) }

  let(:other_company) { create(:company) }
  let(:other_employee) { create(:user, company: other_company) }
  let(:other_category) { create(:category, company: other_company) }

  def submit_as(user, cat: category)
    ClaimWorkflow.submit(employee: user, category: cat, attributes: { amount_halalas: 15_000, description: "Taxi", spent_on: "2026-10-01" })
  end

  def under_review_claim
    submit_as(employee).tap { |claim| ClaimWorkflow.new(claim, approver).start_review }
  end

  describe "employee access" do
    it "returns 403 when an employee lists review claims" do
      get "/api/v1/review/claims", headers: auth_headers(employee)

      expect(response).to have_http_status(:forbidden)
      expect(json).to eq("error" => "Approver access required")
    end

    it "returns 403 when an employee tries to start a review" do
      claim = submit_as(create(:user, company: company))

      post "/api/v1/review/claims/#{claim.id}/start_review", headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(claim.reload.status).to eq("submitted")
    end

    it "returns 403 when an employee manages categories" do
      post "/api/v1/review/categories", params: { category: { name_en: "X", name_ar: "س", limit_halalas: 100 } },
                                        headers: auth_headers(employee), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(Category.count).to eq(0)
    end
  end

  describe "GET /api/v1/review/claims" do
    it "lists all claims of the approver's company only" do
      first = submit_as(employee)
      second = submit_as(create(:user, company: company))
      submit_as(other_employee, cat: other_category)

      get "/api/v1/review/claims", headers: auth_headers(approver)

      expect(response).to have_http_status(:ok)
      expect(json["claims"].map { |c| c["id"] }).to contain_exactly(first.id, second.id)
    end

    it "filters by status" do
      submitted = submit_as(employee)
      under_review_claim

      get "/api/v1/review/claims", params: { status: "submitted" }, headers: auth_headers(approver)

      expect(json["claims"].map { |c| c["id"] }).to eq([submitted.id])
    end
  end

  describe "GET /api/v1/review/claims pagination" do
    it "returns the first 20 claims with page metadata by default" do
      Array.new(21) { submit_as(employee) }

      get "/api/v1/review/claims", headers: auth_headers(approver)

      expect(response).to have_http_status(:ok)
      expect(json["claims"].size).to eq(20)
      expect(json["meta"]).to eq("page" => 1, "per_page" => 20, "total_count" => 21, "total_pages" => 2)
    end

    it "returns the next claims on the second page without overlap, even with identical timestamps" do
      claims = freeze_time { Array.new(3) { submit_as(employee) } }

      get "/api/v1/review/claims", params: { per_page: 2 }, headers: auth_headers(approver)
      first_page = json["claims"].map { |c| c["id"] }
      get "/api/v1/review/claims", params: { per_page: 2, page: 2 }, headers: auth_headers(approver)
      second_page = json["claims"].map { |c| c["id"] }

      expect(first_page).to eq([claims[2].id, claims[1].id])
      expect(second_page).to eq([claims[0].id])
      expect(json["meta"]).to eq("page" => 2, "per_page" => 2, "total_count" => 3, "total_pages" => 2)
    end

    it "caps per_page at 100" do
      submit_as(employee)

      get "/api/v1/review/claims", params: { per_page: 500 }, headers: auth_headers(approver)

      expect(response).to have_http_status(:ok)
      expect(json["meta"]).to include("per_page" => 100, "total_pages" => 1)
    end

    it "paginates within the status filter" do
      submitted = Array.new(3) { submit_as(employee) }
      under_review_claim

      get "/api/v1/review/claims", params: { status: "submitted", per_page: 2, page: 2 }, headers: auth_headers(approver)

      expect(json["claims"].map { |c| c["id"] }).to eq([submitted.first.id])
      expect(json["meta"]).to include("total_count" => 3, "total_pages" => 2)
    end

    it "never includes or counts another company's claims" do
      own = submit_as(employee)
      2.times { submit_as(other_employee, cat: other_category) }

      get "/api/v1/review/claims", headers: auth_headers(approver)

      expect(json["claims"].map { |c| c["id"] }).to eq([own.id])
      expect(json["meta"]).to include("total_count" => 1, "total_pages" => 1)
    end

    it "returns an empty list with correct metadata for a page beyond the last" do
      submit_as(employee)

      get "/api/v1/review/claims", params: { page: 5 }, headers: auth_headers(approver)

      expect(response).to have_http_status(:ok)
      expect(json["claims"]).to eq([])
      expect(json["meta"]).to eq("page" => 5, "per_page" => 20, "total_count" => 1, "total_pages" => 1)
    end

    it "returns 422 for an invalid page" do
      %w[0 -1 abc 1.5].each do |page|
        get "/api/v1/review/claims", params: { page: page }, headers: auth_headers(approver)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json).to eq("error" => "page must be a positive integer")
      end
    end

    it "returns 422 for an invalid per_page" do
      %w[0 -5 ten].each do |per_page|
        get "/api/v1/review/claims", params: { per_page: per_page }, headers: auth_headers(approver)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json).to eq("error" => "per_page must be a positive integer")
      end
    end
  end

  describe "GET /api/v1/review/claims/:id" do
    it "returns a company claim with its timeline and the approver's actions" do
      claim = submit_as(employee)

      get "/api/v1/review/claims/#{claim.id}", headers: auth_headers(approver)

      expect(response).to have_http_status(:ok)
      expect(json["claim"]["available_actions"]).to eq(["start_review"])
      expect(json["claim"]["events"].map { |e| e["action"] }).to eq(["submit"])
    end

    it "returns 404 for another company's claim" do
      claim = submit_as(other_employee, cat: other_category)

      get "/api/v1/review/claims/#{claim.id}", headers: auth_headers(approver)

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Claim not found")
    end
  end

  describe "transitions" do
    it "starts a review and assigns the approver" do
      claim = submit_as(employee)

      post "/api/v1/review/claims/#{claim.id}/start_review", headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["claim"]).to include("status" => "under_review", "available_actions" => %w[approve reject return])
      expect(json["claim"]["reviewer"]["id"]).to eq(approver.id)
    end

    it "returns 403 when an approver starts a review on their own claim" do
      claim = submit_as(approver)

      post "/api/v1/review/claims/#{claim.id}/start_review", headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json).to eq("error" => "You cannot review your own claim")
    end

    it "returns 422 when approving a submitted claim" do
      claim = submit_as(employee)

      post "/api/v1/review/claims/#{claim.id}/approve", headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "Cannot approve a claim that is submitted")
    end

    it "approves a claim under review" do
      claim = under_review_claim

      post "/api/v1/review/claims/#{claim.id}/approve", headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["claim"]["status"]).to eq("approved")
    end

    it "rejects a claim with a reason" do
      claim = under_review_claim

      post "/api/v1/review/claims/#{claim.id}/reject", params: { reason: "Personal expense" }, headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["claim"]["status"]).to eq("rejected")
      expect(json["claim"]["events"].last["comment"]).to eq("Personal expense")
    end

    it "returns 422 when rejecting without a reason" do
      claim = under_review_claim

      post "/api/v1/review/claims/#{claim.id}/reject", params: {}, headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "A reason is required to reject a claim")
    end

    it "returns a claim with a comment" do
      claim = under_review_claim

      post "/api/v1/review/claims/#{claim.id}/return", params: { comment: "Wrong date" }, headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["claim"]["status"]).to eq("returned")
      expect(json["claim"]["events"].last["comment"]).to eq("Wrong date")
    end

    it "returns 422 when returning without a comment" do
      claim = under_review_claim

      post "/api/v1/review/claims/#{claim.id}/return", params: { comment: "" }, headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "A comment is required to return a claim")
    end

    it "returns 404 when starting a review on another company's claim" do
      claim = submit_as(other_employee, cat: other_category)

      post "/api/v1/review/claims/#{claim.id}/start_review", headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:not_found)
      expect(claim.reload.status).to eq("submitted")
    end
  end
end
