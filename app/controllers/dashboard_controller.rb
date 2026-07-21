class DashboardController < ApplicationController
  def index
    @current_user = current_user
    return render :login unless @current_user

    # Gridstack widget izgarası: kullanıcının ilk ziyaretinde varsayılan yerleşimi
    # lazy olarak oluştur (idempotent — .none? kontrolü ile çift oluşumu önler).
    DashboardWidget.seed_defaults_for(@current_user) if @current_user.dashboard_widgets.none?
    @dashboard_widgets = @current_user.dashboard_widgets.order(:position_y, :position_x).to_a

    @chat_rooms = ChatRoom.order(:position)
    @chat_room = @chat_rooms.first

    @learning_skills_empty = @current_user.user_skills.where(direction: "learning").none?
    @recently_scanned_skills = @current_user.user_skills.where(source: "github").includes(:skill).order(weight: :desc)

    @learning_skills_empty = @current_user.user_skills.where(direction: "learning").none?
    @recently_scanned_skills = @current_user.user_skills.where(source: "github").includes(:skill).order(weight: :desc)

    # Eğer tarayıcıdan bir 'q' (query) parametresi gelirse algoritmayı çalıştır
    if params[:q].present?
      if params[:q].to_s.strip.start_with?("#")
        tag_name = params[:q].to_s.strip.delete_prefix("#").strip
        skill = Skill.find_by("LOWER(name) = LOWER(?)", tag_name)
        return redirect_to(skill ? tag_posts_path(tag: skill.name) : root_path)
      end

      # Coklu terim destegi: "react laravel" gibi bosluk ile ayrilmis terimlerin
      # HER BIRINI karsilayan kullanici, sadece BIRINI karsilayandan once siralanir
      # (match_count DESC). Ikincil siralama kriteri average_rating (yuksek puanli once).
      # first(5): asiri uzun/cok terimli sorgularla DB'yi yormayi onlemek icin sinir.
      terms = params[:q].to_s.strip.split(/\s+/).reject(&:blank?).first(5)

      if terms.any?
        like_conditions = terms.map { "LOWER(skills.name) LIKE LOWER(?) OR LOWER(users.name) LIKE LOWER(?)" }.join(" OR ")
        like_values = terms.flat_map { |t| [ "%#{t}%", "%#{t}%" ] }

        @users = User.where.not(id: @current_user.id)
                     .joins(:skills)
                     .where([ like_conditions, *like_values ].flatten)
                     .select("users.*, COUNT(DISTINCT skills.id) AS match_count")
                     .group("users.id")
                     .order(Arel.sql("match_count DESC, COALESCE(users.average_rating, 0) DESC"))
      else
        # Sadece bosluklardan olusan q icin bos sonuc don; MatchFinder'a (eslestirme
        # moduna) duşme - kullanici q parametresi GONDERDIGI icin arama modunda kalmali.
        @users = User.none
      end
    else
      # Parametre yoksa pgvector tabanli capraz eslestirme (teach<->learn) devreye girer
      @users = MatchFinder.call(@current_user)
    end

    # @users her zaman duz bir Array olmali: coklu-terim arama .group() kullandigindan
    # relation uzerinde .count cagirmak Hash donduruyor (grup basina sayim), bu da
    # view'daki `@users.count > 4` sayfalama kontrolunu bozuyor. Tum atama yollarindan
    # (MatchFinder, coklu-terim arama, User.none) sonra TEK noktada materialize ediyoruz.
    @users = @users.to_a

    # Terminal Chat Verilerinin Korunması
    @messages = @chat_room.messages.includes(:user).order(created_at: :asc).last(50)
    @new_message = Message.new

    # Akış için tüm postları en yeniden eskiye sıralayarak çek (N+1 sorgu problemini önlemek için includes kullanıldı)
    @posts = Post.includes(:user, :comments).order(created_at: :desc)
  end
end
