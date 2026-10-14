require "rails_helper"

RSpec.describe "Review categories API" do
  let(:company) { create(:company) }
  let(:approver) { create(:approver, company: company) }
  let(:other_company) { create(:company) }
  let(:other_category) { create(:category, company: other_company, limit_halalas: 30_000) }

  describe "GET /api/v1/review/categories" do
    it "lists the company's categories including inactive ones and nothing from other companies" do
      active = create(:category, company: company, name_en: "Transport")
      inactive = create(:category, company: company, name_en: "Meals", active: false)
      other_category

      get "/api/v1/review/categories", headers: auth_headers(approver)

      expect(response).to have_http_status(:ok)
      expect(json["categories"].map { |c| c["id"] }).to contain_exactly(active.id, inactive.id)
    end
  end

  describe "GET /api/v1/review/categories/:id" do
    it "returns a category of the approver's company" do
      category = create(:category, company: company)

      get "/api/v1/review/categories/#{category.id}", headers: auth_headers(approver)

      expect(response).to have_http_status(:ok)
      expect(json["category"]["id"]).to eq(category.id)
    end

    it "returns 404 for another company's category" do
      get "/api/v1/review/categories/#{other_category.id}", headers: auth_headers(approver)

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Category not found")
    end
  end

  describe "POST /api/v1/review/categories" do
    it "creates a category in the approver's company, ignoring a supplied company" do
      post "/api/v1/review/categories",
           params: { category: { name_en: "Government Fees", name_ar: "رسوم حكومية", limit_halalas: 100_000, company_id: other_company.id } },
           headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:created)
      expect(json["category"]).to include("name_en" => "Government Fees", "name_ar" => "رسوم حكومية", "limit_halalas" => 100_000, "active" => true)
      expect(Category.find(json["category"]["id"]).company).to eq(company)
    end

    it "returns 422 with descriptive messages for invalid data" do
      post "/api/v1/review/categories", params: { category: { name_en: "", name_ar: "رسوم", limit_halalas: 10.5 } },
                                        headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "English name can't be blank and Limit must be an integer")
    end
  end

  describe "PATCH /api/v1/review/categories/:id" do
    it "updates the limit and active flag" do
      category = create(:category, company: company, limit_halalas: 50_000)

      patch "/api/v1/review/categories/#{category.id}", params: { category: { limit_halalas: 20_000, active: false } },
                                                         headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:ok)
      expect(category.reload).to have_attributes(limit_halalas: 20_000, active: false)
    end

    it "does not change the limit snapshot of claims already submitted" do
      category = create(:category, company: company, limit_halalas: 50_000)
      claim = ClaimWorkflow.submit(employee: create(:user, company: company), category: category,
                                   attributes: { amount_halalas: 40_000, description: "Laptop charger", spent_on: "2026-10-01" })

      patch "/api/v1/review/categories/#{category.id}", params: { category: { limit_halalas: 10_000 } },
                                                         headers: auth_headers(approver), as: :json

      expect(claim.reload).to have_attributes(limit_halalas_at_submission: 50_000, amount_halalas: 40_000)
    end

    it "returns 404 for another company's category and leaves it unchanged" do
      patch "/api/v1/review/categories/#{other_category.id}", params: { category: { limit_halalas: 1 } },
                                                               headers: auth_headers(approver), as: :json

      expect(response).to have_http_status(:not_found)
      expect(other_category.reload.limit_halalas).to eq(30_000)
    end
  end
end
