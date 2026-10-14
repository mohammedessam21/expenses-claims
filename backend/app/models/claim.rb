class Claim < ApplicationRecord
  STATUSES = %w[submitted under_review approved rejected returned withdrawn].freeze

  belongs_to :company
  belongs_to :category
  belongs_to :employee, class_name: "User"
  belongs_to :reviewer, class_name: "User", optional: true
  has_many :events, -> { order(:created_at, :id) }, class_name: "ClaimEvent", dependent: :destroy, inverse_of: :claim

  validates :status, inclusion: { in: STATUSES }
  validates :description, :spent_on, presence: true
  validates :amount_halalas, numericality: { only_integer: true, greater_than: 0 }
  validates :limit_halalas_at_submission, numericality: { only_integer: true, greater_than: 0 }
  validate :amount_within_limit
  validate :category_in_same_company

  before_create :assign_reference_code

  private

  def amount_within_limit
    return unless amount_halalas.is_a?(Integer) && limit_halalas_at_submission.is_a?(Integer)
    return if amount_halalas <= limit_halalas_at_submission

    errors.add(:base, "Amount exceeds the category limit of #{Halalas.to_sar(limit_halalas_at_submission)} SAR")
  end

  def category_in_same_company
    return if category.nil? || category.company_id == company_id

    errors.add(:category, "must belong to the same company")
  end

  def assign_reference_code
    self.id ||= self.class.connection.select_value("SELECT nextval(pg_get_serial_sequence('claims', 'id'))")
    self.reference_code = format("CLM-%06d", id)
  end
end
