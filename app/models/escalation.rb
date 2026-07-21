class Escalation < ApplicationRecord
  belongs_to :reported_by, class_name: "User"
  belongs_to :target_user, class_name: "User"
  has_one_attached :evidence_photo

  validates :description, presence: true
end
