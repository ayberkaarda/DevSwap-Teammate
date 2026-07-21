class SkillAlias < ApplicationRecord
  belongs_to :skill
  validates :alias_name, presence: true, uniqueness: true
end
