class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true

  validates :user_id, uniqueness: { scope: [ :likeable_type, :likeable_id ] }

  # Toggle semantigi: begeni varsa kaldirir (false doner), yoksa olusturur (true doner).
  def self.toggle(user:, likeable:)
    existing = find_by(user: user, likeable: likeable)
    if existing
      existing.destroy
      false
    else
      create!(user: user, likeable: likeable)
      true
    end
  end
end
