module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      # Presence: bir WebSocket baglantisi = bir kullanici oturumu (kanal
      # sayisindan bagimsiz). Cevrimici durumunu burada, baglanti seviyesinde
      # isaretlemek, kanal seviyesindeki coklu-abonelik (birden fazla oda/sekme)
      # sorununu tamamen cozer. update_column, callback/validation tetiklemeden
      # hizli yazar.
      current_user&.update_column(:is_online, true)
      # Canli cevrimici listesi: diger izleyicilerin online_users widget'ini guncelle.
      current_user && User.broadcast_online_users_change(current_user)
    end

    def disconnect
      # Baglanti kapaninca (sekme kapandi, ag koptu) cevrimdisi isaretle ve son
      # gorulme zamanini kaydet. update_columns tek UPDATE'te ikisini de yazar.
      current_user&.update_columns(is_online: false, last_seen_at: Time.current)
      # Kopan kullanici artik cevrimdisi: hala cevrimici olan digerlerinin listesinden
      # dusmesi icin onlara yayin yap.
      current_user && User.broadcast_online_users_change(current_user)
    end

    private

    def find_verified_user
      if (user = User.find_by(id: request.session[:user_id]))
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end
