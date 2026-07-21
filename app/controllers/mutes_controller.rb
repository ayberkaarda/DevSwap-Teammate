class MutesController < ApplicationController
  before_action :require_staff

  def create
    target = User.find(params[:user_id])
    if target.protected_from_moderation?
      return redirect_back(fallback_location: root_path, alert: "Bu hesap moderasyondan korunuyor, susturulamaz.")
    end

    duration_minutes = params[:duration_minutes].presence&.to_i || 60
    mute = Mute.new(user: target, muted_by: current_user, reason: params[:reason], muted_until: duration_minutes.minutes.from_now)

    if mute.save
      ActivityLog.record!(
        current_user, "user_muted",
        "#{current_user.name}, #{target.name} kullanicisini #{duration_minutes} dakika susturdu.",
        metadata: { target_id: target.id, duration_minutes: duration_minutes, reason: params[:reason] }
      )
      redirect_back(fallback_location: root_path, notice: "#{target.name} #{duration_minutes} dakika susturuldu.")
    else
      redirect_back(fallback_location: root_path, alert: mute.errors.full_messages.to_sentence)
    end
  end

  def destroy
    mute = Mute.find(params[:id])
    mute.update!(active: false)

    ActivityLog.record!(
      current_user, "user_unmuted",
      "#{current_user.name}, #{mute.user.name} kullanicisinin susturmasini kaldirdi.",
      metadata: { target_id: mute.user_id, mute_id: mute.id }
    )
    redirect_back(fallback_location: root_path, notice: "Susturma kaldırıldı.")
  end
end
