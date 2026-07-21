class RoomsController < ApplicationController
  before_action :require_login

  def show
    @chat_room = ChatRoom.find_by!(slug: params[:slug])

    unless @chat_room.participant?(current_user)
      redirect_to root_path, alert: "Bu odaya erişim yetkin yok." and return
    end

    @chat_rooms = ChatRoom.visible_to(current_user)
    @messages = @chat_room.messages.includes(:user, :message_reactions).order(created_at: :asc).last(50)
    @new_message = Message.new

    # Sag kenar cubugu (DM kisi listesi) + sekme gizleme icin: kullanicinin tum DM
    # odalari (en yeni etkilesim once) ve su an gizli olan oda id'leri.
    @dm_rooms = ChatRoom.dm_rooms_for(current_user)
                        .sort_by { |room| room.messages.maximum(:created_at) || room.created_at }
                        .reverse
    @hidden_room_ids = DismissedConversation.hidden_room_ids_for(current_user)

    # Minimal DM popup (Facebook Messenger tarzi tek-sohbet balonu) icin: SADECE bu
    # tek konusma render edilir — oda sekmeleri (room_tabs) atlanir, yerine karsi
    # katilimcinin avatar+isim basligi gosterilir. Frame promotion mekanizmasi ayni
    # kalir (icerik hala "chat_panel" turbo_frame'i icinde).
    @minimal = params[:minimal].present?
  end

  def start_dm
    target = User.find(params[:user_id])
    return redirect_to root_path, alert: "Kendinle sohbet açamazsın." if target.id == current_user.id

    # origin yalnizca "match" (Dashboard "Baglanti Kur" akisi) veya "direct" (profil
    # "Sohbet Ac", varsayilan) olabilir; keyfi degerler "direct"e indirgenir.
    origin = (params[:origin] == "match") ? "match" : "direct"

    room = ChatRoom.find_or_create_dm_between(current_user, target, origin: origin)
    # Blok varsa ve onceden bir DM yoksa find_or_create_dm_between nil doner: yeni
    # DM acilmasi engellenir (bkz. ChatRoom.find_or_create_dm_between blok kontrolu).
    return redirect_to root_path, alert: "Bu kullanıcıyla mesajlaşamazsın." if room.nil?

    redirect_to room_path(room.slug)
  end

  def request_end
    room = ChatRoom.find_by!(slug: params[:slug])
    return redirect_to root_path, alert: "Bu odaya erişim yetkin yok." unless room.participant?(current_user)

    room.request_end!(current_user)
    redirect_to room_path(room.slug), notice: room.ended? ? "İlişki sonlandı, karşı tarafı değerlendirebilirsin." : "Sonlandırma isteğin kaydedildi, karşı tarafın onayı bekleniyor."
  end

  # DM sekmesini per-user gizle (oda/mesajlar SILINMEZ). Yeni mesaj gelince sekme
  # otomatik geri gorunur (DismissedConversation.hidden_room_ids_for mantigi).
  def dismiss
    room = ChatRoom.find_by!(slug: params[:slug])
    return redirect_to root_path, alert: "Bu odaya erişim yetkin yok." unless room.participant?(current_user)

    DismissedConversation.dismiss!(current_user, room)
    redirect_to root_path, notice: "Sohbet kapatıldı. Yeni mesaj gelince tekrar belirir."
  end
end
