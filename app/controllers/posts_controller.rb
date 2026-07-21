class PostsController < ApplicationController
  before_action :require_login, only: [ :create, :destroy ]
  before_action :require_not_muted, only: [ :create ]

  PER_PAGE = 20

  SORTS  = %w[recent most_liked most_reposted].freeze
  RANGES = %w[all today week month].freeze

  FEED_INCLUDES = [
    :user, :skills, :likes, :reposts, :saved_posts, :post_shares,
    { comments: :user }
  ].freeze

  def index
    # Etiket arama kutusu: "#react" gibi bir girdi geldiginde ilgili etiket
    # akisina yonlendir. Bas/son bosluklar ve opsiyonel '#' onekini temizleriz.
    if params[:tag_search].present?
      tag_name = params[:tag_search].to_s.strip.delete_prefix("#").strip
      if tag_name.present?
        skill = Skill.find_by("LOWER(name) = LOWER(?)", tag_name)
        return redirect_to(skill ? tag_posts_path(tag: skill.name) : posts_path,
                           alert: skill ? nil : "'#{tag_name}' etiketi bulunamadi.")
      end
    end

    @page = params[:page].to_i
    @page = 1 if @page < 1

    @query = PostSearchQuery.new(params[:q])
    @sort  = SORTS.include?(params[:sort]) ? params[:sort] : "recent"
    @range = RANGES.include?(params[:range]) ? params[:range] : "all"

    filtered = Post.all
    filtered = @query.apply(filtered) if @query.present?
    filtered = apply_range(filtered)

    @total = filtered.count
    @posts = apply_sort(apply_preference_order(filtered))
             .includes(*FEED_INCLUDES)
             .limit(PER_PAGE)
             .offset((@page - 1) * PER_PAGE)

    @next_page = (@total > @page * PER_PAGE) ? @page + 1 : nil
    @trending_tags = trending_tags

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @post = Post.includes(:user, :skills, :likes, :reposts, :saved_posts, :post_shares).find(params[:id])
    @comments = @post.comments.top_level
                     .includes(:user, :likes, :comment_reactions,
                               replies: [ :user, :likes, :comment_reactions ])
                     .order(:created_at)
  end

  def by_tag
    @skill = Skill.find_by!(name: params[:tag])
    @posts = Post.tagged_with(@skill)
                 .includes(*FEED_INCLUDES)
                 .order(created_at: :desc)
    @page = 1
    @next_page = nil
    @sort = "recent"
    @range = "all"
    @trending_tags = trending_tags
    render :index
  end

  def create
    # Gelen durum güncellemesini sistemdeki aktif düğüme (sana) bağlayarak kaydet
    post = Post.new(content: params[:content], title: params[:title], user: current_user)
    post.skills = Skill.where(id: params[:skill_ids]) if params[:skill_ids].present?

    if post.save
      # feed=1 param'i yalnizca akis sayfasindaki (posts#index) compose formundan
      # gelir; bu durumda sayfa yenilemeden turbo_stream ile listeye eklenir.
      if params[:feed].present?
        @post = post
        render :create, formats: [ :turbo_stream ]
      else
        redirect_back(fallback_location: root_path, notice: "Post yayınlandı.")
      end
    else
      redirect_back(fallback_location: root_path, alert: post.errors.full_messages.to_sentence)
    end
  end

  def destroy
    post = Post.find(params[:id])
    return head(:forbidden) unless current_user&.staff?

    # Silme olayi admin telemetri log'una dusmeli (backlog: silme islemleri loglanmali).
    ActivityLog.record!(
      current_user, "post_deleted",
      "#{current_user.name} bir postu sildi (##{post.id}): \"#{post.content.to_s.truncate(80)}\""
    )

    post.destroy
    redirect_back(fallback_location: root_path, notice: "Post silindi.")
  end

  private

  # Zaman araligi filtresi: created_at penceresi. Gecersiz/"all" -> filtre yok.
  def apply_range(scope)
    case @range
    when "today" then scope.where("posts.created_at >= ?", Time.current.beginning_of_day)
    when "week"  then scope.where("posts.created_at >= ?", Time.current.beginning_of_week)
    when "month" then scope.where("posts.created_at >= ?", Time.current.beginning_of_month)
    else scope
    end
  end

  # Kisisel feed tercihi siralamasi (BIRINCIL): izleyicinin "ilgileniyorum"
  # isaretledigi yazarlarin postlari en uste, "ilgilenmiyorum" isaretledikleri
  # en alta duser; isaretsiz yazarlar ortada kalir. Mevcut sort (en son / en cok
  # begenilen ...) IKINCIL kriter olarak korunur — apply_sort'un ORDER BY'i bunun
  # ARDINA eklenir. Giris yapmamis ziyaretcide etkisizdir (scope aynen doner).
  #
  # Iliskiyi bir korele alt-sorgu ile kuruyoruz (join+GROUP BY karmasasindan
  # kacinmak icin): posts.user_id, posts.id birincil anahtarina fonksiyonel
  # bagimli oldugundan sayim-tabanli sort'larin GROUP BY posts.id'siyle uyumlu.
  def apply_preference_order(scope)
    return scope unless current_user

    uid = current_user.id.to_i
    scope.order(Arel.sql(
      "CASE (SELECT fp.preference FROM feed_preferences fp " \
      "WHERE fp.target_user_id = posts.user_id AND fp.user_id = #{uid} LIMIT 1) " \
      "WHEN 'interested' THEN 0 WHEN 'not_interested' THEN 2 ELSE 1 END"
    ))
  end

  # Siralama: en son / en cok begenilen / en cok yeniden paylasilan.
  # Sayim tabanli siralamalar left_joins + GROUP BY kullanir; posts.id birincil
  # anahtar oldugundan Postgres SELECT posts.* + GROUP BY posts.id'ye izin verir.
  def apply_sort(scope)
    case @sort
    when "most_liked"
      scope.left_joins(:likes)
           .group("posts.id")
           .order(Arel.sql("COUNT(likes.id) DESC"), created_at: :desc)
    when "most_reposted"
      scope.left_joins(:reposts)
           .group("posts.id")
           .order(Arel.sql("COUNT(reposts.id) DESC"), created_at: :desc)
    else
      scope.order(created_at: :desc)
    end
  end

  # Trend etiketler: HABTM ara tablosu (posts_skills) uzerinden GERCEK post
  # sayisina gore azalan siralama. Skill modeli `posts` iliskisi tanimlamadigi
  # icin (baska bir gorevin sahipligindeki dosya) ara tabloya dogrudan join
  # yapiyoruz — istatistik yine tam olarak post-skill iliskisinden hesaplanir.
  def trending_tags
    Skill.joins("INNER JOIN posts_skills ON posts_skills.skill_id = skills.id")
         .group("skills.id")
         .order(Arel.sql("COUNT(posts_skills.post_id) DESC, skills.name ASC"))
         .limit(10)
  end
end
