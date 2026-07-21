class Admin::WidgetResetsController < ApplicationController
  before_action :require_admin

  # NOT bir moderasyon işlemi (mute/ban gibi) — kullanıcının kendi widget yerleşimini
  # sıfırlamak destek/bug-kurtarma aksiyonu, protected_from_moderation? tarafından
  # engellenmemeli. Bu yüzden MutesController/BansController'ın aksine burada
  # bilinçli olarak protected_from_moderation? guard'ı YOK.
  def reset_dashboard
    target = User.find(params[:user_id])
    DashboardWidget.reset_defaults_for!(target)

    ActivityLog.record!(
      current_user, "admin_dashboard_widgets_reset",
      "#{current_user.name}, #{target.name} kullanıcısının dashboard widget yerleşimini varsayılana sıfırladı.",
      metadata: { target_id: target.id }
    )

    redirect_back fallback_location: telemetry_path,
                  notice: "#{target.name} kullanıcısının dashboard yerleşimi sıfırlandı."
  end

  def reset_profile
    target = User.find(params[:user_id])
    ProfileWidget.reset_defaults_for!(target)

    ActivityLog.record!(
      current_user, "admin_profile_widgets_reset",
      "#{current_user.name}, #{target.name} kullanıcısının profil widget yerleşimini varsayılana sıfırladı.",
      metadata: { target_id: target.id }
    )

    redirect_back fallback_location: telemetry_path,
                  notice: "#{target.name} kullanıcısının profil yerleşimi sıfırlandı."
  end
end
