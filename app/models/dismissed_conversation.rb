class DismissedConversation < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room

  validates :user_id, uniqueness: { scope: :chat_room_id }
  validates :dismissed_at, presence: true

  # Bir kullanicinin bir DM sekmesini "kapatmasi" (kalici, cihazlar arasi):
  # var olan kaydi gunceller, yoksa olusturur. Silme DEGIL — sadece UI gizleme.
  def self.dismiss!(user, chat_room)
    record = find_or_initialize_by(user_id: user.id, chat_room_id: chat_room.id)
    record.dismissed_at = Time.current
    record.save!
    record
  end

  # Su an kullanici icin GIZLI olan oda id'leri: dismissed_at dolu VE o odada
  # dismissed_at'ten SONRA olusmus mesaj YOK. Yeni bir mesaj gelince (created_at >
  # dismissed_at) oda otomatik geri gorunur olur — ayrica bir "un-dismiss" gerekmez.
  def self.hidden_room_ids_for(user)
    where(user_id: user.id).where.not(dismissed_at: nil).filter_map do |dc|
      has_new_message = Message.where(chat_room_id: dc.chat_room_id)
                               .where("created_at > ?", dc.dismissed_at)
                               .exists?
      dc.chat_room_id unless has_new_message
    end
  end
end
