class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room
  has_many :message_reactions, dependent: :destroy

  after_create_commit :broadcast_to_terminal_chat
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy

  def edited?
    edited_at.present?
  end

  private

  def broadcast_to_terminal_chat
    ActionCable.server.broadcast("terminal_chat_channel_#{chat_room.slug}", {
      type: "message",
      id: id,
      message: body,
      user: user.name
    })
  end

  def broadcast_update
    ActionCable.server.broadcast("terminal_chat_channel_#{chat_room.slug}", {
      type: "message_edited",
      id: id,
      message: body,
      user: user.name,
      edited_at: edited_at
    })
  end

  def broadcast_destroy
    ActionCable.server.broadcast("terminal_chat_channel_#{chat_room.slug}", {
      type: "message_deleted",
      id: id
    })
  end
end
