class Company < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception
  has_many :categories, dependent: :restrict_with_exception
  has_many :claims, dependent: :restrict_with_exception

  validates :name, presence: true
end
