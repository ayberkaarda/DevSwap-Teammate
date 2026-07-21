class UserSkillsController < ApplicationController
  before_action :require_login

  def create
    user = current_user
    skill = nil

    # 1. Açılır listeden (dropdown) ID ile yetenek seçimi
    if params[:skill_id].present?
      skill = Skill.find_by(id: params[:skill_id])

      if skill.present? && !user.skills.include?(skill)
        # Eğer direction (learning/teaching) belirtilmediyse varsayılan olarak "teaching" (öğretebileceğim yetenek) atanır
        type = params[:direction].presence || "teaching"
        user.user_skills.create(skill: skill, direction: type)
      end
    # 2. Serbest metin kutusundan (skill_name) yetenek enjeksiyonu.
    # GUVENLIK: Serbest metin ASLA yeni Skill kaydi olusturmaz; yalnizca kanonik
    # havuzdaki mevcut bir yetenegi (alias veya isim eslesmesi ile) bulup baglar.
    elsif params[:skill_name].present?
      key = normalize_skill_name(params[:skill_name])

      alias_match = SkillAlias.find_by(alias_name: key)
      skill = if alias_match
        alias_match.skill
      else
        # Bosluk/nokta ve buyuk-kucuk harf farkini yok sayarak mevcut Skill'i ara.
        Skill.where("LOWER(REPLACE(REPLACE(name, ' ', ''), '.', '')) = ?", key).first
      end

      if skill.present? && !user.skills.include?(skill)
        type = params[:direction].presence || "teaching"
        user.user_skills.create(skill: skill, direction: type)
      end
    # 3. Kontrol paneli (checkbox grid) üzerinden çoklu yetenek seçimi
    elsif params[:skill_ids].present?
      # Aday basina ayri sorgu atmadan (N+1 yok), secilen tum yetenekleri tek sorguda cekeriz
      skills = Skill.where(id: params[:skill_ids])
      type = params[:direction].presence || "teaching"
      now = Time.current

      # Zaten sahip olunan yetenekler hariç, geri kalanı tek seferde toplu insert ederiz
      new_skills = skills.reject { |s| user.skills.include?(s) }
      new_skill_attrs = new_skills.map do |s|
        {
          user_id: user.id,
          skill_id: s.id,
          direction: type,
          source: "manual",
          weight: nil,
          created_at: now,
          updated_at: now
        }
      end

      user.user_skills.insert_all(new_skill_attrs) if new_skill_attrs.any?
    end

    GenerateUserEmbeddingJob.perform_later(user.id)

    # İşlem bitince kullanıcının profil (Kontrol Kulesi) sayfasında kalmasını sağla
    redirect_back(fallback_location: root_path)
  end

  def update
    user_skill = current_user.user_skills.find_by(id: params[:id])
    return head(:not_found) unless user_skill

    if user_skill.update(user_skill_params)
      redirect_back(fallback_location: root_path, notice: "Yetenek güncellendi.")
    else
      redirect_back(fallback_location: root_path, alert: user_skill.errors.full_messages.to_sentence)
    end
  end

  def destroy
    # Eklenen yeteneği silme protokolü
    user_skill = current_user.user_skills.find_by(id: params[:id])
    user_skill&.destroy

    GenerateUserEmbeddingJob.perform_later(current_user.id)

    redirect_back(fallback_location: root_path)
  end

  private

  # Serbest metni kanonik anahtara cevirir. SkillResolver#normalize ve
  # MatchFinder#normalized_skill_name ile BIREBIR AYNI olmali (name.downcase.strip.delete(" .")) -
  # alias verisiyle tutarlilik icin. Not: burada Skill/SkillAlias OLUSTURULMAZ, yalnizca aranir.
  def normalize_skill_name(name)
    name.to_s.downcase.strip.delete(" .")
  end

  def user_skill_params
    params.require(:user_skill).permit(:proficiency_level, :note, :evidence_url)
  end
end
