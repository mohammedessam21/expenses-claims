module ClaimSerializer
  def self.call(claim)
    {
      id: claim.id,
      reference_code: claim.reference_code,
      status: claim.status,
      amount_halalas: claim.amount_halalas,
      limit_halalas_at_submission: claim.limit_halalas_at_submission,
      description: claim.description,
      spent_on: claim.spent_on,
      created_at: claim.created_at,
      category: claim.category.slice(:id, :name_en, :name_ar),
      employee: person(claim.employee),
      reviewer: claim.reviewer && person(claim.reviewer)
    }
  end

  def self.detail(claim, viewer)
    call(claim).merge(
      available_actions: ClaimWorkflow.new(claim, viewer).available_actions,
      events: claim.events.includes(:actor).map { |event| event_json(event) }
    )
  end

  def self.event_json(event)
    {
      id: event.id,
      action: event.action,
      from_status: event.from_status,
      to_status: event.to_status,
      comment: event.comment,
      created_at: event.created_at,
      actor: person(event.actor).merge(role: event.actor.role)
    }
  end

  def self.person(user)
    { id: user.id, name: user.name }
  end
end
