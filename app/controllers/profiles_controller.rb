class ProfilesController < ApplicationController
  before_action :require_login, only: [ :edit, :update, :remove_banner ]

  # Herkese acik profil sayfasi: giris yapmamis ziyaretciler de gorebilir.
  # @match sadece login'li ve baskasinin profiline bakan ziyaretci icin hesaplanir.
  def show
    @profile_user = User.find_by(id: params[:id])
    return redirect_to root_path, alert: "Kullanıcı bulunamadı." if @profile_user.nil?

    # Stalk-önleme (yönlü): profil sahibi ziyaretçiyi engellemişse ziyaretçi
    # profili göremez. (Ziyaretçinin sahibi engellemesi görüntülemeyi engellemez.)
    if current_user && @profile_user.blocking?(current_user)
      return redirect_to root_path, alert: "Bu profili görüntüleyemezsin."
    end

    @teaching_skills = @profile_user.user_skills.where(direction: "teaching")
      .includes(:skill).order(Arel.sql("weight DESC NULLS LAST"))
    @learning_skills = @profile_user.user_skills.where(direction: "learning")
      .includes(:skill).order(Arel.sql("weight DESC NULLS LAST"))
    @repositories = @profile_user.github_repositories.order(stargazers_count: :desc)

    @match = if current_user && current_user.id != @profile_user.id
      MatchFinder.call(current_user).find { |candidate| candidate.id == @profile_user.id }
    end

    # Profil widget'larını ilk görüntülemede lazy oluştur (idempotent, tekrar
    # ziyarette ucuz). Sahibin kaydettiği yerleşim tüm ziyaretçilere aynı gelir.
    ProfileWidget.seed_defaults_for(@profile_user) if ProfileWidget.where(user: @profile_user).none?
    @profile_widgets = ProfileWidget.where(user: @profile_user).order(:position_y, :position_x)
  end

  def edit
    @current_user = current_user
    load_skill_form_data
  end

  def update
    @current_user = current_user
    if @current_user.update(user_params)
      # Turbo Streams ile sonradan burayı sayfa yenilemesiz (SPA) yapacağız
      redirect_to edit_profile_path, notice: "Profil başarıyla senkronize edildi."
    else
      # edit template'i @teaching_skills/@learning_skills/@available_skills
      # bekliyor; hata yolunda da bunları set etmezsek template nil üzerinde patlar.
      load_skill_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def remove_banner
    current_user.banner_image.purge if current_user.banner_image.attached?
    redirect_to edit_profile_path, notice: "Banner kaldırıldı."
  end

  def followers
    @profile_user = User.find_by(id: params[:id])
    return redirect_to root_path, alert: "Kullanıcı bulunamadı." if @profile_user.nil?

    @list_title = "Takipçiler"
    @list_users = @profile_user.followers
    render :follow_list
  end

  def following
    @profile_user = User.find_by(id: params[:id])
    return redirect_to root_path, alert: "Kullanıcı bulunamadı." if @profile_user.nil?

    @list_title = "Takip Edilenler"
    @list_users = @profile_user.following
    render :follow_list
  end

  private

  # edit ve update (hata yolu) tarafından paylaşılan form verisi.
  # Yetenekleri ayrı ayrı çekiyoruz (N+1 sorgu problemini önlemek için includes kullanıyoruz).
  def load_skill_form_data
    @teaching_skills = @current_user.user_skills.where(direction: "teaching").includes(:skill)
    @learning_skills = @current_user.user_skills.where(direction: "learning").includes(:skill)
    # Eklenebilecek tüm yeteneklerin havuzu
    @available_skills = Skill.all
  end

  def user_params
    params.require(:user).permit(:name, :bio, :teaching_format, :availability_note, :banner_image)
  end
end
