class User < ApplicationRecord
  has_many :user_skills, dependent: :destroy
  has_many :skills, through: :user_skills
  has_many :messages, dependent: :destroy
  has_many :github_repositories, dependent: :destroy
  has_many :post_notifications, dependent: :destroy
  has_many :match_digests, dependent: :destroy
  has_many :admin_broadcast_dismissals, dependent: :destroy
  has_many :dashboard_widgets, dependent: :destroy
  has_many :complaints_filed, class_name: "Complaint", foreign_key: :reported_by_id, dependent: :destroy
  has_many :activity_logs
  has_one :user_skill_vector, dependent: :destroy

  # --- Engelleme (Block) ---
  has_many :blocks_made, class_name: "Block", foreign_key: :blocker_id, dependent: :destroy
  has_many :blocks_received, class_name: "Block", foreign_key: :blocked_id, dependent: :destroy
  has_many :blocked_users, through: :blocks_made, source: :blocked

  # --- Takip (Follow) ---
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followee
  has_many :passive_follows, class_name: "Follow", foreign_key: :followee_id, dependent: :destroy
  has_many :followers, through: :passive_follows, source: :follower

  # --- Feed tercihi (ilgileniyorum / ilgilenmiyorum) ---
  has_many :feed_preferences, dependent: :destroy

  encrypts :github_token

  # --- Profil kapak fotoğrafı (banner) ---
  has_one_attached :banner_image

  BANNER_IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  BANNER_IMAGE_MAX_SIZE = 5.megabytes

  validate :banner_image_must_be_valid
  validate :protected_admin_role_cannot_change, if: -> { protected_from_moderation? && role_changed? }

  TEACHING_FORMATS = %w[one_on_one group either].freeze

  validates :teaching_format, inclusion: { in: TEACHING_FORMATS }, allow_nil: true
  validates :availability_note, length: { maximum: 140 }, allow_blank: true

  def admin?
    role == "admin"
  end

  def moderator?
    role == "moderator"
  end

  def staff?
    admin? || moderator?
  end

  def terms_accepted?
    terms_accepted_at.present?
  end

  # `self` bu kullaniciyi engellemis mi? (yonlu: yalnizca self -> other)
  def blocking?(other)
    return false if other.nil?

    blocks_made.exists?(blocked_id: other.id)
  end

  def following?(other)
    return false if other.nil?

    active_follows.exists?(followee_id: other.id)
  end

  def followers_count
    passive_follows.count
  end

  def following_count
    active_follows.count
  end

  # --- Presence: canlı çevrimiçi listesi yayını (Turbo Streams) ---
  # `is_online` ApplicationCable::Connection'da update_column/update_columns ile
  # değiştirildiğinden after_update_commit ATLANIR (bu metodlar callback tetiklemez).
  # Bu yüzden yayın, toggle noktasından (Connection#connect/#disconnect) aşağıdaki
  # metod üzerinden AÇIKÇA tetiklenir.
  #
  # online_users widget'ı HER izleyicinin listesinden KENDİSİNİ hariç tuttuğundan
  # tek bir global partial herkese yayınlanamaz — bu yüzden her izleyicinin kendi
  # per-user stream'ine ("online_users_for_<id>") kendi bakış açısıyla render edilmiş
  # partial yayınlanır.
  def self.broadcast_online_users_change(changed_user)
    online_viewers_excluding(changed_user).find_each do |viewer|
      Turbo::StreamsChannel.broadcast_replace_to(
        "online_users_for_#{viewer.id}",
        target: "online_users_widget_#{viewer.id}",
        partial: "dashboard/widgets/online_users",
        locals: { current_user: viewer }
      )
    end
  end

  # `changed_user` dışında ŞU AN çevrimiçi olan kullanıcılar — online_users widget'ı
  # açık olabilecek ve listesi değişmiş olan izleyiciler. (changed_user'ın kendisi
  # hariç: bağlanan kullanıcı zaten taze sayfa yükler, kopan kullanıcı gitmiştir.)
  def self.online_viewers_excluding(changed_user)
    where(is_online: true).where.not(id: changed_user.id)
  end

  def self.find_or_create_from_omniauth(auth)
    user = find_or_initialize_by(provider: "github", uid: auth.uid)
    user.name = auth.info.name.presence || auth.info.nickname if user.name.blank?
    user.email = auth.info.email if user.email.blank?
    user.avatar_url = auth.info.image
    user.github_username = auth.info.nickname
    user.github_token = auth.credentials.token
    user.save!
    user
  end

  private

  # banner_image doğrulaması: attachment iliştirildiği anda (aynı update/create
  # transaction'ında, blob henüz DB'ye yazılmamışken bile) çalışır. content_type
  # ve byte_size değerleri persist edilmemiş bir blob'ta da bellekten okunabildiği
  # için persisted? guard'ına gerek yoktur; aksi hâlde her normal upload'ta
  # doğrulama atlanırdı. Geçersiz tip veya çok büyük dosyada hata ekler ve
  # attachment'ı purge eder — purge, persist edilmemiş attachment'ta da sorunsuz
  # çalışır, böylece geçersiz bir blob render zamanına kadar hayatta kalmaz.
  # protected_from_moderation ile korunan kurucu admin hesabinin admin yetkisi
  # (baska bir admin tarafindan bile) kaldirilamaz.
  def protected_admin_role_cannot_change
    if role != "admin"
      errors.add(:role, "Bu hesabın admin yetkisi kaldırılamaz.")
    end
  end

  def banner_image_must_be_valid
    return unless banner_image.attached?

    blob = banner_image.blob

    unless blob.content_type.in?(BANNER_IMAGE_CONTENT_TYPES)
      errors.add(:banner_image, "geçerli bir görsel olmalı (PNG, JPEG veya WEBP)")
      return
    end

    if blob.byte_size > BANNER_IMAGE_MAX_SIZE
      errors.add(:banner_image, "5MB'dan büyük olamaz")
    end
  end
end
