class ChatCommandsController < ApplicationController
  # Terminal sohbetindeki GERCEK (sunucu-etkili) slash komutlari: /mute, /unmute,
  # /block, /unblock, /ban ve /unban.
  # Kozmetik komutlardan (/clear, /whoami ...) farkli olarak bu iki komut sunucuya
  # POST atar ve gercekten Mute kaydi olusturur/pasifize eder.
  #
  # Sorumluluk boluşumu: JS tarafi komut SOZDIZIMINI cozer (username + ham sure
  # metni ayirir) ve { username:, duration: } gonderir; sunucu tarafi ise ALAN
  # semantiğini (Turkce sure ayrıştirma) ve TUM guvenlik kurallarini (staff yetkisi,
  # korumali hesap engeli) uygular. Yetki kontrolu client-side gizlemeye GUVENMEZ;
  # non-staff bir kullanici dogrudan POST atsa bile burada reddedilir.
  before_action :require_login

  # POST /chat_commands/mute
  def mute
    return render_forbidden unless current_user&.staff?

    target, error = resolve_target(params[:username])
    return render json: { ok: false, message: error } if error

    if target.protected_from_moderation?
      return render json: { ok: false, message: "Bu hesap moderasyondan korunuyor, susturulamaz." }
    end

    duration_minutes = parse_duration_minutes(params[:duration])
    mute = Mute.new(
      user: target,
      muted_by: current_user,
      reason: "Terminal komutu (/mute)",
      muted_until: duration_minutes.minutes.from_now
    )

    if mute.save
      ActivityLog.record!(
        current_user, "user_muted",
        "#{current_user.name}, #{target.name} kullanicisini terminal komutuyla " \
          "#{duration_minutes} dakika susturdu.",
        metadata: { target_id: target.id, duration_minutes: duration_minutes, via: "chat_command" }
      )
      render json: { ok: true, message: "#{target.name} #{duration_minutes} dakika susturuldu." }
    else
      render json: { ok: false, message: mute.errors.full_messages.to_sentence }
    end
  end

  # POST /chat_commands/unmute
  def unmute
    return render_forbidden unless current_user&.staff?

    target, error = resolve_target(params[:username])
    return render json: { ok: false, message: error } if error

    # Kullanicinin SU AN aktif susturmasini mevcut `active` scope'u uzerinden bul.
    active_mute = Mute.active.find_by(user_id: target.id)
    if active_mute.nil?
      return render json: { ok: false, message: "#{target.name} zaten susturulmuş değil." }
    end

    active_mute.update!(active: false)

    ActivityLog.record!(
      current_user, "user_unmuted",
      "#{current_user.name}, #{target.name} kullanicisinin susturmasini terminal komutuyla kaldirdi.",
      metadata: { target_id: target.id, mute_id: active_mute.id, via: "chat_command" }
    )
    render json: { ok: true, message: "#{target.name} kullanıcısının susturması kaldırıldı." }
  end

  # POST /chat_commands/block
  # Self-service: staff yetkisi GEREKMEZ, her giris yapmis kullanici kendini
  # korumak icin baskasini engelleyebilir (kendisi haric). /mute deseniyle ayni
  # username cozumu + JSON yaniti.
  def block
    target, error = resolve_target(params[:username])
    return render json: { ok: false, message: error } if error

    if target.id == current_user.id
      return render json: { ok: false, message: "Kendini engelleyemezsin." }
    end

    current_user.blocks_made.find_or_create_by(blocked_id: target.id)
    render json: { ok: true, message: "#{target.name} engellendi." }
  end

  # POST /chat_commands/unblock
  def unblock
    target, error = resolve_target(params[:username])
    return render json: { ok: false, message: error } if error

    existing = current_user.blocks_made.find_by(blocked_id: target.id)
    if existing.nil?
      return render json: { ok: false, message: "#{target.name} zaten engelli değil." }
    end

    existing.destroy
    render json: { ok: true, message: "#{target.name} kullanıcısının engeli kaldırıldı." }
  end

  # POST /chat_commands/ban
  # Sadece admin. BansController#create semantigini birebir yansitir: korumali hesap
  # ve GitHub hesabi olmayan kullanici banlanamaz; sure gunler cinsinden, bos/gecersiz
  # ise suresiz (banned_until: nil). Ban kaydi provider/uid uzerinden upsert edilir.
  def ban
    return render_forbidden unless current_user&.admin?

    target, error = resolve_target(params[:username])
    return render json: { ok: false, message: error } if error

    if target.protected_from_moderation?
      return render json: { ok: false, message: "Bu hesap moderasyondan korunuyor, banlanamaz." }
    end
    if target.provider.blank? || target.uid.blank?
      return render json: { ok: false, message: "Bu kullanıcının GitHub hesabı yok, banlanamaz." }
    end

    duration_days = parse_duration_days(params[:duration])
    banned_until = duration_days.present? && duration_days.positive? ? duration_days.days.from_now : nil

    ban = BannedAccount.find_or_initialize_by(provider: target.provider, uid: target.uid)
    ban.assign_attributes(reason: "Terminal komutu (/ban)", banned_until: banned_until, active: true, banned_by: current_user)

    if ban.save
      ActivityLog.record!(
        current_user, "user_banned",
        "#{current_user.name}, #{target.name} kullanicisini terminal komutuyla " \
          "#{banned_until ? "#{duration_days} gun" : "suresiz"} banladi.",
        metadata: { target_id: target.id, duration_days: duration_days, via: "chat_command" }
      )
      message = banned_until ? "#{target.name} #{duration_days} gün banlandı." : "#{target.name} süresiz banlandı."
      render json: { ok: true, message: message }
    else
      render json: { ok: false, message: ban.errors.full_messages.to_sentence }
    end
  end

  # POST /chat_commands/unban
  # Sadece admin. BansController#destroy gibi kaydi SILMEZ, sadece pasifize eder.
  def unban
    return render_forbidden unless current_user&.admin?

    target, error = resolve_target(params[:username])
    return render json: { ok: false, message: error } if error

    # Kullanicinin SU AN aktif banini `active` scope'u uzerinden provider/uid ile bul.
    active_ban = BannedAccount.active.find_by(provider: target.provider, uid: target.uid)
    if active_ban.nil?
      return render json: { ok: false, message: "#{target.name} zaten banlı değil." }
    end

    active_ban.update!(active: false)

    ActivityLog.record!(
      current_user, "user_unbanned",
      "#{current_user.name}, #{target.name} kullanicisinin banini terminal komutuyla kaldirdi.",
      metadata: { target_id: target.id, ban_id: active_ban.id, via: "chat_command" }
    )
    render json: { ok: true, message: "#{target.name} kullanıcısının banı kaldırıldı." }
  end

  private

  def render_forbidden
    render json: { ok: false, message: "Bu işlem için yetkin yok." }, status: :forbidden
  end

  # Ismi (case-insensitive) tam eslesme ile kullaniciya cozer. Sifir veya birden
  # fazla eslesmede net bir hata mesaji dondurur (tahmin etmez).
  # Donus: [user_or_nil, error_message_or_nil]
  def resolve_target(raw_name)
    name = raw_name.to_s.strip
    return [ nil, "Kullanıcı adı belirtmelisin." ] if name.blank?

    matches = User.where("LOWER(name) = LOWER(?)", name).to_a
    case matches.size
    when 0 then [ nil, "'#{name}' adında bir kullanıcı bulunamadı." ]
    when 1 then [ matches.first, nil ]
    else [ nil, "'#{name}' adıyla birden fazla kullanıcı var, işlem yapılamadı." ]
    end
  end

  # Serbest metin sureyi dakikaya cevirir:
  #   "30 dakika" / "30 dk" / "30" -> 30
  #   "1 saat"    / "1 sa"         -> 60
  # Taninabilir bir sey yoksa 60 dakika (MutesController varsayilan semantigi).
  def parse_duration_minutes(text)
    match = text.to_s.strip.downcase.match(/(\d+)\s*(saat|sa|dakika|dk)?/)
    return 60 unless match

    amount = match[1].to_i
    case match[2]
    when "saat", "sa" then amount * 60
    else amount # "dakika", "dk" veya birimsiz cıplak sayı -> dakika
    end
  end

  # Serbest metinden ban suresini GUN cinsinden cikartir (BansController semantigi):
  #   "7 gün" / "7 gun" / "7" -> 7
  #   ""      / rakam yoksa    -> nil (suresiz ban -> banned_until: nil)
  # DIKKAT: parse_duration_minutes'tan farkli olarak bos/gecersizde 60 degil nil doner.
  def parse_duration_days(text)
    match = text.to_s.strip.match(/\d+/)
    match ? match[0].to_i : nil
  end
end
