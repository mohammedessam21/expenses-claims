class Category < ApplicationRecord
  MAX_LIMIT_HALALAS = 2_147_483_647

  belongs_to :company
  has_many :claims, dependent: :restrict_with_exception

  scope :active, -> { where(active: true) }

  validates :name_en, :name_ar, presence: true
  validates :limit_halalas, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_LIMIT_HALALAS }
end
