class NotificationsController < ApplicationController
  before_action :require_login
  before_action :set_notification, only: [ :dismiss, :claim ]

  PER_PAGE = 20

  # Tum zamanlarin bildirim gecmisi. Zil menusu ve dashboard widget'i yalnizca
  # son/aktif bildirimleri gosterirken bu sayfa TUM bildirimleri (aktif + kapatilmis)
  # en yeni ustte, sayfalanmis olarak listeler. Sayfa ziyaret edilince aktif
  # bildirimler "gorulmus" (seen) isaretlenir; zil rozetindeki sayaç bosalir.
  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1

    scope = current_user.post_notifications.includes(:post, :skill).order(created_at: :desc)
    @total = scope.count
    @notifications = scope.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    @next_page = (@total > @page * PER_PAGE) ? @page + 1 : nil

    mark_active_seen!
  end

  # Zil menusu acildiginda (details toggle) cagrilir: o an aktif ve henuz
  # gorulmemis bildirimleri "gorulmus" isaretler. Boylece "+N" rozeti kalkar.
  def mark_seen
    mark_active_seen!
    head :no_content
  end

  def dismiss
    @notification.update!(dismissed_at: Time.current)
    redirect_back(fallback_location: root_path)
  end

  def claim
    @notification.update!(dismissed_at: Time.current, claimed_at: Time.current)

    # "Başkasıyla eşleşince diğerlerinden kaybolsun": aynı post'a ait TÜM
    # diğer aktif bildirimleri de dismiss et (cascade).
    PostNotification.active
                    .where(post_id: @notification.post_id)
                    .where.not(id: @notification.id)
                    .update_all(dismissed_at: Time.current)

    redirect_back(fallback_location: root_path)
  end

  private

  def set_notification
    @notification = current_user.post_notifications.find(params[:id])
  end

  def mark_active_seen!
    current_user.post_notifications.active.unseen.update_all(seen_at: Time.current)
  end
end
