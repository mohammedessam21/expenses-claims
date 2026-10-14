class User < ApplicationRecord
  ROLES = %w[employee approver].freeze

  has_secure_password

  generates_token_for :auth, expires_in: 12.hours do
    password_salt.last(10)
  end

  belongs_to :company
  has_many :claims, foreign_key: :employee_id, inverse_of: :employee, dependent: :restrict_with_exception

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  def approver?
    role == "approver"
  end
end
