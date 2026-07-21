class FollowsController < ApplicationController
  before_action :require_login

  # Takip et / birak (toggle). target_user_id: takip edilecek/birakilacak kullanici.
  # Zaten takip ediyorsa kaydi siler, etmiyorsa olusturur. Kendini takip engellenir
  # (model validasyonu + burada erken donus).
  def toggle
    target = User.find_by(id: params[:target_user_id] || params[:id])
    return redirect_back(fallback_location: root_path, alert: "Kullanıcı bulunamadı.") if target.nil?
    return redirect_back(fallback_location: root_path, alert: "Kendini takip edemezsin.") if target.id == current_user.id

    existing = current_user.active_follows.find_by(followee_id: target.id)
    if existing
      existing.destroy
      notice = "#{target.name} takipten çıkarıldı."
    else
      current_user.active_follows.create(followee_id: target.id)
      notice = "#{target.name} takip ediliyor."
    end

    redirect_back(fallback_location: public_profile_path(target.id), notice: notice)
  end
end
