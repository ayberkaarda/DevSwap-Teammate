class MessagesController < ApplicationController
  before_action :require_login
  before_action :require_not_muted, only: [ :create ]

  rate_limit to: 20, within: 1.minute, only: :create,
    with: -> { head :too_many_requests }

  def create
    cleaned_body = message_params[:body].to_s.strip
    return head(:no_content) if cleaned_body.blank?

    chat_room = ChatRoom.find_by(slug: params[:room]) || ChatRoom.order(:position).first

    unless chat_room.participant?(current_user)
      return head(:forbidden)
    end

    @message = current_user.messages.build(body: cleaned_body, chat_room: chat_room)
    @message.save
    head :no_content
  end

  # Yalnizca mesajin SAHIBI kendi mesajini duzenleyebilir. Basarili duzenlemede
  # body + edited_at guncellenir ve Message modelinin after_update_commit callback'i
  # duzenlemeyi ilgili ActionCable kanalina yayinlar (canli guncelleme).
  def update
    message = Message.find(params[:id])
    return head(:forbidden) unless message.user_id == current_user.id

    cleaned_body = message_params[:body].to_s.strip
    return head(:unprocessable_entity) if cleaned_body.blank?

    original_body = message.body
    message.update!(body: cleaned_body, edited_at: Time.current)

    ActivityLog.record!(
      current_user, "message_edited",
      "#{current_user.name} bir mesajı düzenledi (##{message.id}): " \
        "\"#{original_body.to_s.truncate(60)}\" → \"#{cleaned_body.truncate(60)}\""
    )

    head :no_content
  end

  # Mesajin SAHIBI veya staff (admin/moderator) silebilir. Silmeden ONCE govde
  # yakalanip admin telemetri log'una yazilir; ardindan Message'in
  # after_destroy_commit callback'i silmeyi ActionCable kanalina yayinlar.
  def destroy
    message = Message.find(params[:id])
    return head(:forbidden) unless message.user_id == current_user.id || current_user.staff?

    captured_body = message.body.to_s

    ActivityLog.record!(
      current_user, "message_deleted",
      "#{current_user.name} bir mesajı sildi (##{message.id}): \"#{captured_body.truncate(80)}\""
    )

    message.destroy
    head :no_content
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
