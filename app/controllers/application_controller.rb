class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes


  before_action :enforce_not_banned
  before_action :require_terms_acceptance



  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_login
    unless current_user
      redirect_to root_path, alert: "Devam etmek için GitHub ile giriş yapmalısın."
    end
  end


  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Bu sayfa için yönetici yetkisi gerekiyor."
    end
  end

  def enforce_not_banned
    return unless current_user
    return unless BannedAccount.banned?(current_user.provider, current_user.uid)

    reset_session
    redirect_to root_path, alert: "Bu hesap yasaklandı."
  end

  def require_not_muted
    if Mute.active_for?(current_user)
      redirect_to root_path, alert: "Şu an susturulmuş durumdasın, içerik paylaşamazsın."
    end
  end

  def require_staff
    unless current_user&.staff?
      redirect_to root_path, alert: "Bu işlem için yetkin yok."
    end
  end

  def require_terms_acceptance
    return unless current_user
    return if current_user.terms_accepted?
    return if controller_name == "terms"
    return if controller_name == "sessions"

    redirect_to terms_path, alert: "Devam etmeden önce kuralları okuyup onaylaman gerekiyor."
  end
end
