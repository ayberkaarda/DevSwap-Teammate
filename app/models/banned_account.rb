class BannedAccount < ApplicationRecord
  belongs_to :banned_by, class_name: "User"

  scope :active, -> { where(active: true).where("banned_until IS NULL OR banned_until > ?", Time.current) }

  def self.banned?(provider, uid)
    return false if provider.blank? || uid.blank?

    active.exists?(provider: provider, uid: uid)
  end

  def permanent?
    banned_until.nil?
  end
end
