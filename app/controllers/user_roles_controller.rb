class UserRolesController < ApplicationController
  before_action :require_admin

  ALLOWED_ROLES = %w[member moderator admin].freeze

  def update
    user = User.find(params[:id])
    role = params[:role]

    unless ALLOWED_ROLES.include?(role)
      return redirect_to telemetry_path, alert: "Geçersiz rol."
    end

    # Korunan kurucu admin hesabinin admin yetkisi baska bir admin tarafindan bile
    # alinamaz (model validasyonu ile birlikte defans-in-depth; burada daha net mesaj).
    if user.protected_from_moderation? && role != "admin"
      return redirect_to telemetry_path, alert: "Bu hesabın admin yetkisi kaldırılamaz."
    end

    user.update!(role: role)
    redirect_to telemetry_path, notice: "#{user.name} artık '#{role}'."
  end
end
