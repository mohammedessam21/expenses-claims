require "rails_helper"

RSpec.describe ClaimWorkflow do
  let(:company) { create(:company) }
  let(:employee) { create(:user, company: company) }
  let(:approver) { create(:approver, company: company) }
  let(:other_approver) { create(:approver, company: company) }
  let(:category) { create(:category, company: company, limit_halalas: 50_000) }

  def submit_claim(owner: employee, amount: 15_000)
    described_class.submit(
      employee: owner,
      category: category,
      attributes: { amount_halalas: amount, description: "Taxi", spent_on: Date.new(2026, 10, 1) }
    )
  end

  def claim_in(status, reviewer: approver)
    claim = submit_claim
    claim.update_columns(status: status, reviewer_id: status == "submitted" ? nil : reviewer.id)
    claim
  end

  def workflow(claim, actor)
    described_class.new(claim, actor)
  end

  describe ".submit" do
    it "creates a submitted claim with server-assigned fields and a submit event" do
      claim = submit_claim

      expect(claim).to be_persisted
      expect(claim).to have_attributes(
        status: "submitted", company: company, employee: employee, reviewer: nil,
        limit_halalas_at_submission: 50_000, amount_halalas: 15_000
      )
      expect(claim.reference_code).to match(/\ACLM-\d{6}\z/)
      expect(claim.events.map { |e| [e.action, e.from_status, e.to_status, e.actor] })
        .to eq([["submit", nil, "submitted", employee]])
    end

    it "rejects an amount above the category limit and saves nothing" do
      expect { submit_claim(amount: 50_001) }
        .to raise_error(ActiveRecord::RecordInvalid, /Amount exceeds the category limit of 500.00 SAR/)
      expect(Claim.count).to eq(0)
      expect(ClaimEvent.count).to eq(0)
    end

    it "rejects an inactive category" do
      category.update!(active: false)

      expect { submit_claim }.to raise_error(ClaimWorkflow::InvalidTransition, "Category is not active")
    end
  end

  describe "#start_review" do
    it "moves a submitted claim to under_review and assigns the approver as reviewer" do
      claim = claim_in("submitted")

      workflow(claim, approver).start_review

      expect(claim.reload).to have_attributes(status: "under_review", reviewer: approver)
      expect(claim.events.last).to have_attributes(action: "start_review", actor: approver, from_status: "submitted", to_status: "under_review")
    end

    it "does not let an approver review their own claim" do
      claim = submit_claim(owner: approver)

      expect { workflow(claim, approver).start_review }
        .to raise_error(ClaimWorkflow::NotPermitted, "You cannot review your own claim")
      expect(claim.reload.status).to eq("submitted")
    end

    it "does not let an employee start a review" do
      claim = claim_in("submitted")

      expect { workflow(claim, create(:user, company: company)).start_review }
        .to raise_error(ClaimWorkflow::NotPermitted, "Only approvers can start a review")
    end

    it "does not let an approver from another company start a review" do
      claim = claim_in("submitted")

      expect { workflow(claim, create(:approver)).start_review }.to raise_error(ClaimWorkflow::NotPermitted)
    end

    it "cannot start a review on a claim that is already under review" do
      claim = claim_in("under_review")

      expect { workflow(claim, other_approver).start_review }
        .to raise_error(ClaimWorkflow::InvalidTransition, "Cannot start review on a claim that is under review")
    end
  end

  describe "#approve" do
    it "approves a claim under review by its reviewer" do
      claim = claim_in("under_review")

      workflow(claim, approver).approve

      expect(claim.reload.status).to eq("approved")
      expect(claim.events.last).to have_attributes(action: "approve", from_status: "under_review", to_status: "approved", actor: approver)
    end

    it "cannot approve a submitted claim" do
      claim = claim_in("submitted")

      expect { workflow(claim, approver).approve }
        .to raise_error(ClaimWorkflow::InvalidTransition, "Cannot approve a claim that is submitted")
      expect(claim.reload.status).to eq("submitted")
      expect(claim.events.count).to eq(1)
    end

    it "only lets the reviewer approve" do
      claim = claim_in("under_review")

      expect { workflow(claim, other_approver).approve }
        .to raise_error(ClaimWorkflow::NotPermitted, "Only the reviewer can approve this claim")
    end
  end

  describe "#reject" do
    it "rejects a claim under review with a reason" do
      claim = claim_in("under_review")

      workflow(claim, approver).reject("Not a business expense")

      expect(claim.reload.status).to eq("rejected")
      expect(claim.events.last).to have_attributes(action: "reject", comment: "Not a business expense", to_status: "rejected")
    end

    it "requires a reason" do
      claim = claim_in("under_review")

      expect { workflow(claim, approver).reject("  ") }
        .to raise_error(ClaimWorkflow::InvalidTransition, "A reason is required to reject a claim")
      expect(claim.reload.status).to eq("under_review")
    end

    it "cannot reject an approved claim" do
      claim = claim_in("approved")

      expect { workflow(claim, approver).reject("Late") }
        .to raise_error(ClaimWorkflow::InvalidTransition, "Cannot reject a claim that is approved")
    end
  end

  describe "#return_claim" do
    it "returns a claim under review to the employee with a comment" do
      claim = claim_in("under_review")

      workflow(claim, approver).return_claim("Please correct the amount")

      expect(claim.reload.status).to eq("returned")
      expect(claim.events.last).to have_attributes(action: "return", comment: "Please correct the amount", from_status: "under_review", to_status: "returned")
    end

    it "requires a comment" do
      claim = claim_in("under_review")

      expect { workflow(claim, approver).return_claim("") }
        .to raise_error(ClaimWorkflow::InvalidTransition, "A comment is required to return a claim")
    end
  end

  describe "#resubmit" do
    it "lets the employee edit amount and description and moves the claim back to submitted" do
      claim = claim_in("returned")

      workflow(claim, employee).resubmit(amount_halalas: 12_000, description: "Corrected taxi fare")

      expect(claim.reload).to have_attributes(status: "submitted", amount_halalas: 12_000, description: "Corrected taxi fare", reviewer: nil)
      expect(claim.events.last).to have_attributes(action: "resubmit", from_status: "returned", to_status: "submitted", actor: employee)
    end

    it "re-checks the amount against the limit captured at submission" do
      claim = claim_in("returned")
      category.update!(limit_halalas: 10_000)

      workflow(claim, employee).resubmit(amount_halalas: 40_000)

      expect(claim.reload).to have_attributes(amount_halalas: 40_000, limit_halalas_at_submission: 50_000)
    end

    it "rejects an edited amount above the limit and leaves the claim unchanged" do
      claim = claim_in("returned")

      expect { workflow(claim, employee).resubmit(amount_halalas: 60_000) }
        .to raise_error(ActiveRecord::RecordInvalid, /Amount exceeds the category limit of 500.00 SAR/)
      expect(claim.reload).to have_attributes(status: "returned", amount_halalas: 15_000)
      expect(claim.events.pluck(:action)).to eq(["submit"])
    end

    it "only lets the claim's employee resubmit" do
      claim = claim_in("returned")

      expect { workflow(claim, approver).resubmit(description: "x") }
        .to raise_error(ClaimWorkflow::NotPermitted, "Only the claim's employee can resubmit this claim")
    end

    it "cannot resubmit a submitted claim" do
      claim = claim_in("submitted")

      expect { workflow(claim, employee).resubmit(description: "x") }
        .to raise_error(ClaimWorkflow::InvalidTransition, "Cannot resubmit a claim that is submitted")
    end
  end

  describe "#withdraw" do
    it "withdraws a submitted claim" do
      claim = claim_in("submitted")

      workflow(claim, employee).withdraw

      expect(claim.reload.status).to eq("withdrawn")
      expect(claim.events.last).to have_attributes(action: "withdraw", from_status: "submitted", to_status: "withdrawn")
    end

    it "withdraws a returned claim" do
      claim = claim_in("returned")

      workflow(claim, employee).withdraw

      expect(claim.reload.status).to eq("withdrawn")
    end

    it "cannot withdraw a claim under review" do
      claim = claim_in("under_review")

      expect { workflow(claim, employee).withdraw }
        .to raise_error(ClaimWorkflow::InvalidTransition, "Cannot withdraw a claim that is under review")
    end

    it "only lets the claim's employee withdraw" do
      claim = claim_in("submitted")

      expect { workflow(claim, approver).withdraw }
        .to raise_error(ClaimWorkflow::NotPermitted, "Only the claim's employee can withdraw this claim")
    end
  end

  describe "transactions" do
    it "keeps the old status when writing the event fails" do
      claim = claim_in("submitted")
      allow(claim.events).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(ClaimEvent.new))

      expect { workflow(claim, approver).start_review }.to raise_error(ActiveRecord::RecordInvalid)

      expect(claim.reload).to have_attributes(status: "submitted", reviewer_id: nil)
      expect(claim.events.count).to eq(1)
    end
  end

  describe "#available_actions" do
    it "offers start_review to an approver on a submitted claim" do
      expect(workflow(claim_in("submitted"), approver).available_actions).to eq(%w[start_review])
    end

    it "offers only withdraw to an approver on their own submitted claim" do
      expect(workflow(submit_claim(owner: approver), approver).available_actions).to eq(%w[withdraw])
    end

    it "offers approve, reject and return only to the reviewer" do
      claim = claim_in("under_review")

      expect(workflow(claim, approver).available_actions).to eq(%w[approve reject return])
      expect(workflow(claim, other_approver).available_actions).to eq([])
    end

    it "offers resubmit and withdraw to the employee on a returned claim" do
      expect(workflow(claim_in("returned"), employee).available_actions).to eq(%w[resubmit withdraw])
    end
  end
end
