class Block < ApplicationRecord
  belongs_to :blocker, class_name: "User"
  belongs_to :blocked, class_name: "User"

  validates :blocker_id, uniqueness: { scope: :blocked_id }
  validate :cannot_block_self

  # Iki kullanici arasinda HERHANGI bir yonde (a->b VEYA b->a) blok var mi?
  # Mesajlasma/eslesme engellemesi bu iki-yonlu kontrolu kullanir: taraflardan
  # biri digerini engellemisse, artik hicbir taraf yeni DM acamaz / eslesemez.
  def self.blocked_between?(user_a, user_b)
    return false if user_a.nil? || user_b.nil?

    where(blocker_id: user_a.id, blocked_id: user_b.id)
      .or(where(blocker_id: user_b.id, blocked_id: user_a.id))
      .exists?
  end

  # `viewer`, `profile_owner` tarafindan engellenmis mi? Profil goruntuleme
  # kisitlamasi YONLU'dur: yalnizca ENGELLENEN taraf, engelleyenin profilini
  # goremez ("beni engelleyeni stalklayamam"). Engelleyen, engellediginin
  # profilini gormeye devam edebilir.
  def self.blocks?(blocker, blocked)
    return false if blocker.nil? || blocked.nil?

    where(blocker_id: blocker.id, blocked_id: blocked.id).exists?
  end

  private

  def cannot_block_self
    errors.add(:blocked_id, "kendini engelleyemezsin") if blocker_id == blocked_id
  end
end
