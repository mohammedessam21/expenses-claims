class ClaimWorkflow
  class Error < StandardError; end
  class InvalidTransition < Error; end
  class NotPermitted < Error; end

  TRANSITIONS = {
    "start_review" => { from: %w[submitted], to: "under_review" },
    "approve" => { from: %w[under_review], to: "approved" },
    "reject" => { from: %w[under_review], to: "rejected" },
    "return" => { from: %w[under_review], to: "returned" },
    "resubmit" => { from: %w[returned], to: "submitted" },
    "withdraw" => { from: %w[submitted returned], to: "withdrawn" }
  }.freeze

  REVIEWER_ACTIONS = %w[approve reject return].freeze
  EMPLOYEE_ACTIONS = %w[resubmit withdraw].freeze
  RESUBMIT_FIELDS = %i[amount_halalas description].freeze

  def self.submit(employee:, category:, attributes:)
    raise InvalidTransition, "Category is not active" unless category.active?

    claim = employee.claims.build(attributes)
    claim.assign_attributes(
      company: employee.company,
      category: category,
      status: "submitted",
      limit_halalas_at_submission: category.limit_halalas
    )

    Claim.transaction do
      claim.save!
      claim.events.create!(actor: employee, action: "submit", to_status: "submitted")
    end
    claim
  end

  attr_reader :claim, :actor

  def initialize(claim, actor)
    @claim = claim
    @actor = actor
  end

  def start_review
    transition!("start_review", changes: { reviewer: actor })
  end

  def approve
    transition!("approve")
  end

  def reject(reason)
    ensure_allowed!("reject")
    transition!("reject", comment: required_text!(reason, "A reason is required to reject a claim"))
  end

  def return_claim(comment)
    ensure_allowed!("return")
    transition!("return", comment: required_text!(comment, "A comment is required to return a claim"))
  end

  def resubmit(edits = {})
    changes = edits.to_h.symbolize_keys.slice(*RESUBMIT_FIELDS)
    transition!("resubmit", changes: changes.merge(reviewer: nil))
  end

  def withdraw
    transition!("withdraw")
  end

  def available_actions
    TRANSITIONS.keys.select { |action| valid_from_current_status?(action) && permission_error(action).nil? }
  end

  private

  def transition!(action, comment: nil, changes: {})
    ensure_allowed!(action)
    from_status = claim.status

    Claim.transaction do
      claim.update!(changes.merge(status: TRANSITIONS.fetch(action)[:to]))
      claim.events.create!(actor: actor, action: action, from_status: from_status, to_status: claim.status, comment: comment)
    end
    claim
  end

  def ensure_allowed!(action)
    raise InvalidTransition, invalid_transition_message(action) unless valid_from_current_status?(action)

    message = permission_error(action)
    raise NotPermitted, message if message
  end

  def valid_from_current_status?(action)
    TRANSITIONS.fetch(action)[:from].include?(claim.status)
  end

  def invalid_transition_message(action)
    verb = action == "start_review" ? "start review on" : action
    "Cannot #{verb} a claim that is #{claim.status.humanize(capitalize: false)}"
  end

  def permission_error(action)
    return "You do not have access to this claim" unless actor.company_id == claim.company_id

    if action == "start_review"
      start_review_permission_error
    elsif REVIEWER_ACTIONS.include?(action)
      "Only the reviewer can #{action} this claim" unless claim.reviewer_id == actor.id
    elsif EMPLOYEE_ACTIONS.include?(action)
      "Only the claim's employee can #{action} this claim" unless claim.employee_id == actor.id
    end
  end

  def start_review_permission_error
    return "Only approvers can start a review" unless actor.approver?

    "You cannot review your own claim" if claim.employee_id == actor.id
  end

  def required_text!(text, message)
    raise InvalidTransition, message if text.to_s.strip.empty?

    text.strip
  end
end
