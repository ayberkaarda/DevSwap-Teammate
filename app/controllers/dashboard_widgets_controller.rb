class DashboardWidgetsController < ApplicationController
  before_action :require_login

  # Gridstack.js drag/resize sonrası TOPLU layout kaydı (tek istek, tüm değişen widget'lar).
  # Beklenen gövde: { widgets: [{ id:, position_x:, position_y:, width:, height: }, ...] }
  # Güvenlik: her id current_user'a ait olmalı; olmayan tek bir id bile tüm işlemi 422 ile reddeder.
  def reorder
    incoming = params.permit(widgets: [ :id, :position_x, :position_y, :width, :height ])[:widgets] || []

    owned = current_user.dashboard_widgets.where(id: incoming.map { |w| w[:id] }).index_by(&:id)

    ActiveRecord::Base.transaction do
      incoming.each do |attrs|
        widget = owned[attrs[:id].to_i]
        raise ActiveRecord::Rollback unless widget

        widget.update!(
          position_x: attrs[:position_x],
          position_y: attrs[:position_y],
          width: attrs[:width],
          height: attrs[:height]
        )
      end
    end

    # Sahiplenme veya doğrulama başarısızsa (rollback veya sayı uyuşmazlığı) 422 dön.
    if incoming.any? { |attrs| owned[attrs[:id].to_i].nil? }
      head :unprocessable_entity
    else
      head :ok
    end
  end

  # Tekil widget güncellemesi: edit mode'daki per-widget kontroller (font ölçeği / görünürlük).
  def update
    widget = current_user.dashboard_widgets.find_by(id: params[:id])
    return head(:unprocessable_entity) unless widget

    if widget.update(widget_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  # Kullanıcının dashboard yerleşimini varsayılana sıfırlar ("Varsayılana Dön" butonu).
  def reset
    DashboardWidget.reset_defaults_for!(current_user)
    redirect_to root_path, notice: "Dashboard yerleşimin varsayılana sıfırlandı."
  end

  private

  def widget_params
    params.require(:dashboard_widget).permit(:font_scale, :visible)
  end
end
