
class UserSkillVector < ApplicationRecord
  belongs_to :user

  has_neighbors :embedding_teach, dimensions: 512
  has_neighbors :embedding_learn, dimensions: 512
end

# app/models/user_skill_vector.rb
class UserSkillVector < ApplicationRecord
  belongs_to :user
end
