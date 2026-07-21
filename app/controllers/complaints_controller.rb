class ComplaintsController < ApplicationController
  before_action :require_login

  # Sikayetci kullanicinin actigi tum sikayetler + durum takibi.
  def index
    @complaints = current_user.complaints_filed.includes(:target_user).order(created_at: :desc)
  end

  def create
    target, error = resolve_target
    return redirect_back(fallback_location: root_path, alert: error) if error
    return redirect_to root_path, alert: "Kendini şikayet edemezsin." if target.id == current_user.id

    complaint = Complaint.new(reported_by: current_user, target_user: target, description: params[:description])
    complaint.evidence_photo.attach(params[:evidence_photo]) if params[:evidence_photo].present?

    if complaint.save
      redirect_back(fallback_location: root_path, notice: "Şikayetin alındı.")
    else
      redirect_back(fallback_location: root_path, alert: complaint.errors.full_messages.to_sentence)
    end
  end

  private

  # Hedef kullaniciyi ya target_user_id (profil butonu) ya da target_username
  # (sohbet slash komutu / modal) uzerinden cozer. Isim eslesmesi case-insensitive
  # tam eslesmedir; sifir/coklu eslesmede net hata dondurur (ChatCommandsController
  # ile ayni desen). Donus: [user_or_nil, error_message_or_nil].
  def resolve_target
    if params[:target_user_id].present?
      user = User.find_by(id: params[:target_user_id])
      return [ nil, "Kullanıcı bulunamadı." ] if user.nil?

      return [ user, nil ]
    end

    name = params[:target_username].to_s.strip
    return [ nil, "Şikayet edilecek kullanıcı belirtilmedi." ] if name.blank?

    matches = User.where("LOWER(name) = LOWER(?)", name).to_a
    case matches.size
    when 0 then [ nil, "'#{name}' adında bir kullanıcı bulunamadı." ]
    when 1 then [ matches.first, nil ]
    else [ nil, "'#{name}' adıyla birden fazla kullanıcı var, işlem yapılamadı." ]
    end
  end
end
