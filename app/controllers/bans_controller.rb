class BansController < ApplicationController
  before_action :require_admin

  def create
    user = User.find(params[:user_id])
    return redirect_to telemetry_path, alert: "Bu hesap moderasyondan korunuyor, banlanamaz." if user.protected_from_moderation?
    return redirect_to telemetry_path, alert: "Bu kullanıcının GitHub hesabı yok, banlanamaz." if user.provider.blank? || user.uid.blank?

    duration_days = params[:duration_days].presence&.to_i
    banned_until = duration_days.present? && duration_days.positive? ? duration_days.days.from_now : nil

    ban = BannedAccount.find_or_initialize_by(provider: user.provider, uid: user.uid)
    ban.assign_attributes(reason: params[:reason], banned_until: banned_until, active: true, banned_by: current_user)
    ban.save!

    redirect_to telemetry_path, notice: "#{user.name} banlandı."
  end

  def destroy
    ban = BannedAccount.find(params[:id])
    ban.update!(active: false)
    redirect_to telemetry_path, notice: "Ban kaldırıldı."
  end
end
