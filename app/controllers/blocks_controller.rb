class BlocksController < ApplicationController
  before_action :require_login

  # Bir kullaniciyi engelle. Self-service: her giris yapmis kullanici, kendisi
  # disinda herhangi birini engelleyebilir (staff yetkisi gerekmez).
  def create
    target = User.find_by(id: params[:blocked_id] || params[:target_user_id])
    return redirect_back(fallback_location: root_path, alert: "Kullanıcı bulunamadı.") if target.nil?
    return redirect_back(fallback_location: root_path, alert: "Kendini engelleyemezsin.") if target.id == current_user.id

    current_user.blocks_made.find_or_create_by(blocked_id: target.id)
    redirect_back(fallback_location: public_profile_path(target.id), notice: "#{target.name} engellendi.")
  end

  # Engeli kaldir. Sadece engeli koyan taraf kendi engelini kaldirabilir.
  def destroy
    block = current_user.blocks_made.find_by(id: params[:id]) ||
            current_user.blocks_made.find_by(blocked_id: params[:blocked_id])
    block&.destroy
    redirect_back(fallback_location: settings_path, notice: "Engel kaldırıldı.")
  end
end
