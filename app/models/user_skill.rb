class UserSkill < ApplicationRecord
  belongs_to :user
  belongs_to :skill

  PROFICIENCY_LEVELS = %w[beginner intermediate advanced expert].freeze

  validates :source, inclusion: { in: %w[manual github] }
  validates :proficiency_level, inclusion: { in: PROFICIENCY_LEVELS }, allow_blank: true
  validates :evidence_url, format: { with: /\Ahttps?:\/\// }, allow_blank: true
end
