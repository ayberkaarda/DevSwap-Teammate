class TerminalChatChannel < ApplicationCable::Channel
  def subscribed
    room_slug = params[:room].presence || "genel"
    chat_room = ChatRoom.find_by(slug: room_slug)

    # Yetkilendirme spoof edilebilen params[:user]'a DEGIL, sunucuda
    # request.session[:user_id] uzerinden dogrulanan connection.current_user'a
    # dayanir. Ozel (DM) odalar her zaman DB'de bulunur; boylece yalnizca gercek
    # katilimcilar stream'e abone olabilir. Genel odalar herkese aciktir.
    if chat_room && !chat_room.participant?(connection.current_user)
      reject
      return
    end

    stream_from "terminal_chat_channel_#{room_slug}"

    if params[:user].present?
      stream_from "user_#{params[:user]}_feed"
    end

    # Stream name "terminal_chat_channel" must stay in sync with the Message model and JS subscription; also used by the dev_feed.
    stream_from "terminal_chat_channel"


    # Global sohbet akışı - herkes bu stream'e abone (topluluk sohbeti, kasıtlı olarak global)
    stream_from "terminal_chat_channel"

    # Kullanıcıya özel bildirim kanalı (mention, read receipt vb. için altyapı)
    if params[:user].present?
      stream_from "user_#{params[:user]}_feed"
    end
  end

  # Klavye vuruşunu algıladığında yayın yap (sunucu-tarafı debounce ile taşkın koruması)
  def typing(data)
    user = data["user"]
    return if user.blank?

    room_slug = data["room"].presence || "genel"
    debounce_key = "typing_debounce:#{room_slug}:#{user}"
    return if Rails.cache.exist?(debounce_key)

    Rails.cache.write(debounce_key, true, expires_in: 2.seconds)
    ActionCable.server.broadcast("terminal_chat_channel_#{room_slug}", { type: "typing", user: user })

    user = data["user"]

    user = data["user"]

    return if user.blank?

    debounce_key = "typing_debounce:#{user}"
    return if Rails.cache.exist?(debounce_key)

    Rails.cache.write(debounce_key, true, expires_in: 2.seconds)
    ActionCable.server.broadcast("terminal_chat_channel", { type: "typing", user: user })
  end

  # Bir mesaj okundu isaretlendiginde read receipt yayinla (idempotent).
  def mark_read(data)
    message = Message.find_by(id: data["message_id"])
    return unless message
    return if message.read_at.present?

    message.update_column(:read_at, Time.current)
    ActionCable.server.broadcast(
      "terminal_chat_channel_#{message.chat_room.slug}",
      { type: "read_receipt", message_id: message.id }
    )
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
