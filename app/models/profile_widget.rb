class ProfileWidget < ApplicationRecord
  belongs_to :user

  # Opak string anahtarlar — profil view partial'ları bunlara göre switch yapar.
  # DashboardWidget ile aynı desen (Rails enum bilinçli olarak KULLANILMADI).
  WIDGET_TYPES = %w[
    identity
    teaching_skills
    learning_skills
    github_repos
    reposts
  ].freeze

  # Izgara kolon sayısı — her widget'ın yatay sınır kutusu bunu aşamaz.
  GRID_COLUMNS = 12

  # Varsayılan yerleşim (12 kolonluk grid) — Facebook tarzı iki sütun.
  # Avatar/isim/butonlar SABİT header'a taşındığından "identity" widget'ı artık
  # yalnızca durum/biyo/format taşıyan İNCE bir kart; bu yüzden varsayılan
  # yüksekliği düşürüldü (6 -> 4) ve altındaki reposts yukarı reflow edildi.
  # Sol sütun (dar, 4/12): identity + reposts stacked. Sağ sütun (geniş, 8/12):
  # öğretme/öğrenme yetenekleri + repos. 5 widget'ın hepsi GÖRÜNÜR gelir.
  DEFAULT_LAYOUT = [
    # --- Sol sütun (dar): ince "Hakkında" kartı + repost'lar stacked ---
    { widget_type: "identity",        position_x: 0, position_y: 0,  width: 4, height: 4, visible: true },
    { widget_type: "reposts",         position_x: 0, position_y: 4,  width: 4, height: 5, visible: true },
    # --- Sağ sütun (geniş): yetenek matrisi + repos ---
    { widget_type: "teaching_skills", position_x: 4, position_y: 0,  width: 8, height: 4, visible: true },
    { widget_type: "learning_skills", position_x: 4, position_y: 4,  width: 8, height: 3, visible: true },
    { widget_type: "github_repos",    position_x: 4, position_y: 7,  width: 8, height: 4, visible: true }
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

  # Kullanıcının profili ilk görüntülendiğinde (lazy) 5 widget'ı varsayılan
  # yerleşimle oluşturur. Idempotent: .none? kontrolüyle çağrılmalı; unique
  # index sayesinde tekrar çağrılsa bile çift oluşmaz. Oluşturulanları döndürür.
  def self.seed_defaults_for(user)
    DEFAULT_LAYOUT.map do |attrs|
      ProfileWidget.create!(attrs.merge(user: user))
    end
  end

  # Kullanıcının mevcut tüm profil widget'larını siler ve varsayılan yerleşimi
  # yeniden oluşturur. seed_defaults_for'un aksine (yalnızca hiç widget yokken
  # güvenli), bu metod HER ZAMAN çağrılabilir — "varsayılana dön" butonu için.
  def self.reset_defaults_for!(user)
    transaction do
      ProfileWidget.where(user: user).destroy_all
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
