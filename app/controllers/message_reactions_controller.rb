class MessageReactionsController < ApplicationController
  before_action :require_login

  # Chat mesajina emoji tepkisi ekle/kaldir (toggle). Yalnizca ilgili odanin
  # katilimcilari tepki verebilir. Degisiklikten sonra guncel emoji sayilari ayni
  # ActionCable kanalina yayinlanir; DOM guncellemesi takip eden UI ajaninin isi.
  def toggle
    @message = Message.find(params[:id])
    emoji = params[:emoji].to_s

    unless MessageReaction::ALLOWED_EMOJI.include?(emoji)
      return head :unprocessable_entity
    end

    unless @message.chat_room.participant?(current_user)
      return head :forbidden
    end

    MessageReaction.toggle(user: current_user, message: @message, emoji: emoji)

    ActionCable.server.broadcast(
      "terminal_chat_channel_#{@message.chat_room.slug}",
      {
        type: "message_reaction",
        message_id: @message.id,
        reactions: MessageReaction.counts_for(@message)
      }
    )

    head :no_content
  end
end
