class RepostsController < ApplicationController
  before_action :require_login

  def toggle
    @post = Post.find(params[:id])
    Repost.toggle(user: current_user, post: @post)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: post_path(@post) }
      format.json { head :ok }
    end
  end

  # Repost eden kullanicilarin isim+foto listesi (profil linki icin).
  def post_reposters
    @post = Post.find(params[:id])
    reposters = User.where(id: Repost.where(post: @post).select(:user_id)).order(:name)

    respond_to do |format|
      format.html { render partial: "reposts/reposters", locals: { users: reposters }, layout: false }
      format.json { render json: reposters.map { |u| { id: u.id, name: u.name, avatar_url: u.avatar_url } } }
    end
  end
end
