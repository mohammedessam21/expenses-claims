class ClaimEvent < ApplicationRecord
  belongs_to :claim
  belongs_to :actor, class_name: "User"

  validates :action, :to_status, presence: true
end
