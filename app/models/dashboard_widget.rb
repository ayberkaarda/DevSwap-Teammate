class DashboardWidget < ApplicationRecord
  belongs_to :user

  # Opak string anahtarlar — view partial'ları/frontend bunlara göre switch yapar.
  # Rails enum KULLANILMADI (bilinçli): bunlar sıralı/sayısal durum değil, sadece tür anahtarı.
  #
  # NOT (Faz 31 düzeltme): "dev_feed" (GLOBAL_AĞ_AKIŞI post yayın widget'ı) grid'den
  # tamamen emekli edildi ve telemetry sayfasına taşındı. Artık geçerli bir widget
  # türü DEĞİL; ne seed edilir ne de render edilir. (Sağ-alttaki ayrı yüzen
  # #dev-feed-terminal JS log widget'ı bununla ilgisizdir, o dokunulmadı.)
  WIDGET_TYPES = %w[
    chatbox
    match_algorithm
    weather
    clock
    online_users
    recent_contacts
    notifications
    recent_posts
    quick_actions
    activity_graph
    terminal_shortcuts
  ].freeze

  # Izgara kolon sayısı — her widget'ın yatay sınır kutusu bunu aşamaz.
  GRID_COLUMNS = 12

  # Varsayılan yerleşim. 12 kolonluk grid; çakışmayan, görsel olarak dengeli bir
  # başlangıç düzeni (31c drag/resize ile yeniden dizilebilir).
  #
  # `visible:` başına: İlk girişte 12 widget'ı üst üste "kusmamak" için yalnızca
  # ÇEKİRDEK, kullanışlı bir set (chatbox, match_algorithm, recent_posts,
  # quick_actions, notifications, clock) varsayılan GÖRÜNÜR gelir. Geri kalanlar
  # (weather, online_users, recent_contacts, activity_graph, terminal_shortcuts)
  # seed edilir ama visible:false başlar — kullanıcı "Düzenle" > "Gizli" listesinden
  # tek tıkla açabilir. Böylece hiçbir widget kaybolmaz, dashboard temiz açılır.
  DEFAULT_LAYOUT = [
    # --- Varsayılan GÖRÜNÜR çekirdek set ---
    { widget_type: "chatbox",           position_x: 0, position_y: 0,  width: 6, height: 5, visible: true },
    { widget_type: "match_algorithm",   position_x: 6, position_y: 0,  width: 6, height: 3, visible: true },
    { widget_type: "notifications",     position_x: 6, position_y: 3,  width: 3, height: 2, visible: true },
    { widget_type: "clock",             position_x: 9, position_y: 3,  width: 3, height: 2, visible: true },
    { widget_type: "recent_posts",      position_x: 0, position_y: 5,  width: 7, height: 4, visible: true },
    { widget_type: "quick_actions",     position_x: 7, position_y: 5,  width: 5, height: 4, visible: true },
    # --- Varsayılan GİZLİ (seed edilir, "Gizli" listesinden açılabilir) ---
    { widget_type: "weather",           position_x: 0, position_y: 9,  width: 4, height: 3, visible: false },
    { widget_type: "online_users",      position_x: 4, position_y: 9,  width: 4, height: 3, visible: false },
    { widget_type: "recent_contacts",   position_x: 8, position_y: 9,  width: 4, height: 4, visible: false },
    { widget_type: "activity_graph",    position_x: 0, position_y: 12, width: 7, height: 3, visible: false },
    { widget_type: "terminal_shortcuts", position_x: 7, position_y: 12, width: 5, height: 3, visible: false }
  ].freeze

  validates :widget_type, presence: true,
                          inclusion: { in: WIDGET_TYPES },
                          uniqueness: { scope: :user_id }
  validates :position_x, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position_y, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :width, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 12 }
  validates :height, numericality: { only_integer: true, greater_than: 0 }
  validates :font_scale, numericality: { greater_than_or_equal_to: 0.5, less_than_or_equal_to: 2.0 }
  validates :visible, inclusion: { in: [ true, false ] }

  # Çakışma önleme sertleştirmesi: bir widget'ın yatay sınır kutusu 12 kolonluk
  # ızgarayı asla aşamaz (position_x + width <= 12). Gridstack sürükleme/boyut
  # sırasında bunu istemci tarafında zorlar; bu doğrulama, doğrudan/racy bir
  # reorder PATCH'inin ızgara dışına taşan (dolayısıyla görsel çakışmaya yol
  # açan) bir geometriyi DB'ye yazmasını sunucu tarafında engeller.
  validate :fits_within_grid_columns

  # Kullanıcının ilk ziyaretinde (lazy) tüm 12 widget'ı varsayılan yerleşimle oluşturur.
  # Idempotent: .none? kontrolüyle çağrılmalı; çağıran taraf tekrar çağırsa bile
  # unique index sayesinde çift oluşmaz. Oluşturulan widget'ları döndürür.
  def self.seed_defaults_for(user)
    DEFAULT_LAYOUT.map do |attrs|
      user.dashboard_widgets.create!(attrs)
    end
  end

  # Kullanıcının mevcut tüm widget'larını siler ve varsayılan yerleşimi yeniden
  # oluşturur. seed_defaults_for'un aksine (yalnızca hiç widget yokken güvenli),
  # bu metod HER ZAMAN çağrılabilir — "varsayılana dön" butonu için.
  def self.reset_defaults_for!(user)
    transaction do
      user.dashboard_widgets.destroy_all
      seed_defaults_for(user)
    end
  end

  private

  def fits_within_grid_columns
    return if position_x.blank? || width.blank?

    if position_x + width > GRID_COLUMNS
      errors.add(:width, "ızgara sınırını aşıyor (position_x + width, #{GRID_COLUMNS} kolonu geçemez)")
    end
  end
end
