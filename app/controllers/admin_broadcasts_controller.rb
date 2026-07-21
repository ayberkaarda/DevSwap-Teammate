class AdminBroadcastsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :require_login
  before_action :require_admin, only: [ :create, :destroy ]
  before_action :set_broadcast, only: [ :destroy, :dismiss ]

  def create
    broadcast = AdminBroadcast.new(admin: current_user, message: params[:message], expires_at: expires_at_from_duration)

    if broadcast.save
      # Su an cevrimici olan tum giris yapmis kullanicilara sayfa yenilemeden
      # ilet: layout'ta herkesin abone oldugu "global_announcements" stream'ine
      # yeni duyuruyu listenin basina ekle.
      Turbo::StreamsChannel.broadcast_prepend_to(
        "global_announcements",
        target: "global-announcements-list",
        partial: "admin_broadcasts/broadcast",
        locals: { broadcast: broadcast }
      )
      redirect_to telemetry_path, notice: "Duyuru yayınlandı."
    else
      redirect_to telemetry_path, alert: broadcast.errors.full_messages.to_sentence
    end
  end

  # Herhangi bir giris yapmis kullanici kendi banner gorunumunden bu duyuruyu
  # kapatabilir (sadece kendisi icin — DismissedConversation ile ayni desen).
  # Icerik silinmez: notifications#index'te "gecmis duyuru" olarak gorunmeye devam eder.
  def dismiss
    AdminBroadcastDismissal.dismiss!(current_user, @broadcast)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@broadcast)) }
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  # Admin-only: duyuruyu veritabanindan tamamen siler. Hala goren tum
  # kullanicilarin ekranindan da canli olarak kaldirmak icin ayni
  # "global_announcements" stream'ine bir remove yayini yapilir.
  def destroy
    dom_id_value = dom_id(@broadcast)
    @broadcast.destroy!

    Turbo::StreamsChannel.broadcast_remove_to(
      "global_announcements",
      target: dom_id_value
    )

    redirect_to telemetry_path, notice: "Duyuru silindi."
  end

  private

  def set_broadcast
    @broadcast = AdminBroadcast.find(params[:id])
  end

  # Formdaki "sure" secimini (duration_hours) mutlak son gecerlilik anina cevirir.
  # Bos ya da "0" => suresiz (nil): duyuru elle kaldirilana kadar durur.
  def expires_at_from_duration
    hours = params[:duration_hours].presence&.to_i
    return nil if hours.nil? || hours <= 0

    hours.hours.from_now
  end
end
