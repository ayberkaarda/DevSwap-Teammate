class FeedPreferencesController < ApplicationController
  before_action :require_login

  # Bir post yazarina yonelik feed tercihini upsert eder (ilgileniyorum /
  # ilgilenmiyorum). Ayni yazar icin var olan tercih guncellenir (find_or_initialize).
  def create
    target = User.find_by(id: params[:target_user_id])
    return respond(false, "Kullanıcı bulunamadı.") if target.nil?
    return respond(false, "Kendine tercih belirleyemezsin.") if target.id == current_user.id

    preference = params[:preference].to_s
    unless FeedPreference::PREFERENCES.include?(preference)
      return respond(false, "Geçersiz tercih.")
    end

    pref = current_user.feed_preferences.find_or_initialize_by(target_user_id: target.id)
    pref.preference = preference

    if pref.save
      label = (preference == FeedPreference::INTERESTED) ? "İlgileniyorum" : "İlgilenmiyorum"
      respond(true, "#{target.name} için tercih kaydedildi: #{label}.")
    else
      respond(false, pref.errors.full_messages.to_sentence)
    end
  end

  # Bir yazara yonelik tercihi tamamen kaldirir (notr duruma dondurur). Settings
  # sayfasindaki "İlgilenmediklerim" listesinden "geri al" ile cagrilir.
  def destroy
    pref = current_user.feed_preferences.find_by(target_user_id: params[:id] || params[:target_user_id])
    pref&.destroy
    redirect_back(fallback_location: settings_path, notice: "Tercih kaldırıldı.")
  end

  private

  def respond(ok, message)
    respond_to do |format|
      format.json { render json: { ok: ok, message: message }, status: ok ? :ok : :unprocessable_entity }
      format.html do
        flash_key = ok ? :notice : :alert
        redirect_back(fallback_location: posts_path, flash_key => message)
      end
    end
  end
end
