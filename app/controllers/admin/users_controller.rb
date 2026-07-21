class Admin::UsersController < ApplicationController
  before_action :require_staff

  PER_PAGE = 25

  def index
    @q = params[:q].to_s.strip
    @filter = params[:filter].to_s

    scope = User.all
    if @q.present?
      like = "%#{@q.downcase}%"
      scope = scope.where(
        "LOWER(name) LIKE :q OR LOWER(email) LIKE :q OR LOWER(github_username) LIKE :q",
        q: like
      )
    end

    scope = apply_filter(scope, @filter)

    @page = [ params[:page].to_i, 1 ].max
    @total = scope.count
    @users = scope.order(Arel.sql("LOWER(name) ASC NULLS LAST"), :id)
                  .limit(PER_PAGE)
                  .offset((@page - 1) * PER_PAGE)
    @next_page = (@total > @page * PER_PAGE) ? @page + 1 : nil

    # Only ban records that actually key onto a user (provider + uid present).
    @banned_pairs = BannedAccount.active
                                 .where.not(provider: nil, uid: nil)
                                 .pluck(:provider, :uid)
                                 .to_set
    @muted_user_ids = Mute.active.pluck(:user_id).to_set
  end

  helper_method :user_banned?, :user_muted?

  private

  def apply_filter(scope, filter)
    case filter
    when "admin", "moderator", "member"
      scope.where(role: filter)
    when "banned"
      pairs = BannedAccount.active
                           .where.not(provider: nil, uid: nil)
                           .pluck(:provider, :uid)
      return scope.none if pairs.empty?

      conditions = pairs.map { "(provider = ? AND uid = ?)" }.join(" OR ")
      scope.where(conditions, *pairs.flatten)
    when "muted"
      scope.where(id: Mute.active.select(:user_id))
    else
      scope
    end
  end

  def user_banned?(user)
    return false if user.provider.blank? || user.uid.blank?

    @banned_pairs.include?([ user.provider, user.uid ])
  end

  def user_muted?(user)
    @muted_user_ids.include?(user.id)
  end
end
