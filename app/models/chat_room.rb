class ChatRoom < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :dismissed_conversations, dependent: :destroy

  belongs_to :user_a, class_name: "User", optional: true
  belongs_to :user_b, class_name: "User", optional: true

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :public_rooms, -> { where(private: false) }

  def self.dm_rooms_for(user)
    where(private: true).where("user_a_id = :id OR user_b_id = :id", id: user.id)
  end

  # Bir kullanicinin gorebilecegi tum odalar: genel odalar + kendi DM odalari.
  def self.visible_to(user)
    public_rooms.or(dm_rooms_for(user)).order(:position, :id)
  end

  # origin: "match" (Dashboard "Bağlantı Kur" eşleşme akışı) veya "direct"
  # (profil "Sohbet Aç" akışı, varsayılan). ÖNEMLİ: origin YALNIZCA oda ilk kez
  # oluşturulurken (find_or_create_by!'in blok'u yalnız create'te çalışır) atanır;
  # zaten var olan bir odaya tekrar bakıldığında origin DEĞİŞTİRİLMEZ — böylece
  # "match" ile kurulmuş bir ilişki, sonradan profilden "Sohbet Aç" ile açılınca
  # "direct"e düşmez. (Bu blok-yalnız-create semantiği testle doğrulanır.)
  def self.find_or_create_dm_between(user_one, user_two, origin: "direct")
    raise ArgumentError, "iki farkli kullanici gerekli" if user_one.id == user_two.id

    lower, higher = [ user_one, user_two ].sort_by(&:id)

    # Blok kontrolu (iki yonlu): taraflardan biri digerini engellemisse YENI bir DM
    # acilamaz. Var olan (blok oncesi) bir DM ise korunur ve dondurulur; yalnizca
    # yeni oda olusturulmasi engellenir. Blok + mevcut oda yoksa nil doner (cagiran
    # tarafin alert ile durumu ele almasi beklenir).
    if Block.blocked_between?(lower, higher)
      return find_by(user_a: lower, user_b: higher)
    end

    room = find_or_create_by!(user_a: lower, user_b: higher) do |new_room|
      new_room.private = true
      new_room.slug = "dm-#{lower.id}-#{higher.id}"
      new_room.name = "Özel Mesaj"
      new_room.position = 999
      new_room.origin = origin
    end

    # Yalnizca oda BU cagride ILK KEZ olusturulduysa (idempotent re-fetch'te DEGIL)
    # ve match-origin ise, her iki katilimcinin dashboard "eslesme" widget'indaki
    # ilgili karti canli olarak "Sohbete Git"e cevir. previously_new_record?
    # find_or_create_by!'in create dalinda true, mevcut oda bulundugunda false'tur.
    room.broadcast_match_connection_established if room.previously_new_record? && room.match_origin?

    room
  end

  # Eşleşme kaynaklı DM mi? İlişki sonlandırma/değerlendirme UI'ı yalnızca bunlarda
  # gösterilir; "direct" DM'ler sıradan bir sohbet gibi görünür.
  def match_origin?
    private? && origin == "match"
  end

  # Match kaynakli DM ilk kez kurulunca her iki katilimcinin per-user "matches"
  # stream'ine, KARSI tarafin kartini connected:true (yani "Sohbete Git") haliyle
  # yayinlar. Boylece diger katilimci (veya acik baska sekmeler) sayfa yenilemeden
  # kartin butonunun degistigini gorur. Ilk "Baglanti Kur" tiklamasinin normal
  # request/response akisi (redirect) DEGISMEZ — bu yalnizca EK bir canli guncelleme.
  def broadcast_match_connection_established
    [ user_a, user_b ].each do |viewer|
      other = other_participant(viewer)
      next unless viewer && other

      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{viewer.id}_matches",
        target: "match_user_card_#{other.id}",
        partial: "dashboard/widgets/match_user_card",
        locals: { user: other, connected: true }
      )
    end
  end

  def participant?(user)
    return true unless private?

    user.present? && [ user_a_id, user_b_id ].include?(user.id)
  end

  def display_name_for(viewer)
    return name unless private?

    other = (user_a_id == viewer&.id) ? user_b : user_a
    other&.name || "Özel Sohbet"
  end

  def request_end!(user)
    return false unless private? && participant?(user)

    if user_a_id == user.id
      update!(ended_by_a: true)
    elsif user_b_id == user.id
      update!(ended_by_b: true)
    end
  end

  def ended?
    private? && ended_by_a? && ended_by_b?
  end

  def other_participant(user)
    return nil unless private?

    user_a_id == user.id ? user_b : user_a
  end

  def rated_by?(user)
    ratings.exists?(rater_id: user&.id)
  end

  # Bu odada `user`'in okumadigi (kendi gonderdikleri haric) mesaj sayisi. Sekme
  # rozetinde "+2"/"+9" gibi gosterilir.
  def unread_count_for(user)
    return 0 unless user

    messages.where(read_at: nil).where.not(user_id: user.id).count
  end
end
