class Complaint < ApplicationRecord
  STATUSES = %w[pending reviewed actioned dismissed].freeze

  belongs_to :reported_by, class_name: "User"
  belongs_to :target_user, class_name: "User"
  # Opsiyonel: post uc-nokta menusunden acilan sikayetlerde hangi postun tetikledigi.
  belongs_to :post, optional: true
  has_one_attached :evidence_photo

  validates :description, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
end
