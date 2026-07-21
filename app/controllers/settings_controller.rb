class SettingsController < ApplicationController
  before_action :require_login

  # Birlesik "Ayarlar" sayfasi: kaydedilenler, ilgilenmediklerim, engellenenler.
  def show
    @saved_posts = Post.joins(:saved_posts)
                       .where(saved_posts: { user_id: current_user.id })
                       .includes(:user, :skills, :likes, :reposts, :saved_posts, :post_shares)
                       .order("saved_posts.created_at DESC")

    @not_interested = current_user.feed_preferences
                                  .not_interested
                                  .includes(:target_user)
                                  .order(created_at: :desc)

    @blocked = current_user.blocks_made.includes(:blocked).order(created_at: :desc)
  end
end
