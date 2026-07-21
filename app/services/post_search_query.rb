# GitHub-tarzi post arama sozdizimini ayristiran kucuk bir PORO.
#
# Desteklenen sozdizimi (hepsi opsiyonel, sirasiz, buyuk/kucuk harf duyarsiz):
#   Users:ayberk          -> yazar adinda "ayberk" gecen postlar (substring)
#   user:ayberk           -> ayni (tekil form da kabul edilir)
#   tag:react,laravel     -> React VEYA Laravel etiketli postlar (ANY match)
#   serbest metin         -> icerik/baslikta substring araması
#
# Ornek: "Users:ayberk tag:react,laravel turbo stream"
#   usernames -> ["ayberk"], tags -> ["react", "laravel"], text -> "turbo stream"
class PostSearchQuery
  attr_reader :usernames, :tags, :text

  USER_TOKEN = /\b(?:users?):(\S+)/i
  TAG_TOKEN  = /\btag:(\S+)/i

  def initialize(raw)
    @raw = raw.to_s
    @usernames = []
    @tags = []
    @text = ""
    parse!
  end

  # Herhangi bir filtre bileseni cikti mi? (arama kutusu bos degilse true).
  def present?
    @usernames.any? || @tags.any? || @text.present?
  end

  # Verilen Post scope'una ayristirilmis filtreleri uygular ve yeni scope doner.
  def apply(scope)
    scope = filter_by_users(scope)
    scope = filter_by_tags(scope)
    scope = filter_by_text(scope)
    scope
  end

  private

  def parse!
    leftover = @raw.dup

    leftover = leftover.gsub(USER_TOKEN) do
      value = strip_quotes(Regexp.last_match(1))
      @usernames << value if value.present?
      " "
    end

    leftover = leftover.gsub(TAG_TOKEN) do
      strip_quotes(Regexp.last_match(1)).split(",").each do |t|
        t = t.strip
        @tags << t if t.present?
      end
      " "
    end

    @text = leftover.squeeze(" ").strip
  end

  def strip_quotes(str)
    str.to_s.delete('"').strip
  end

  def filter_by_users(scope)
    return scope if @usernames.empty?

    clauses = @usernames.map { "LOWER(users.name) LIKE ?" }
    values  = @usernames.map { |u| "%#{u.downcase}%" }
    scope.joins(:user).where(clauses.join(" OR "), *values)
  end

  def filter_by_tags(scope)
    return scope if @tags.empty?

    skill_ids = Skill.where("LOWER(name) IN (?)", @tags.map(&:downcase)).select(:id)
    # Alt sorgu ile join cogaltmasini (ve DISTINCT/GROUP BY karmasasini) onleriz.
    scope.where(id: Post.joins(:skills).where(skills: { id: skill_ids }))
  end

  def filter_by_text(scope)
    return scope if @text.blank?

    scope.where("posts.content ILIKE :q OR posts.title ILIKE :q", q: "%#{@text}%")
  end
end
