class LikesController < ApplicationController
  before_action :require_login

  def toggle_post
    @post = Post.find(params[:id])
    Like.toggle(user: current_user, likeable: @post)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: post_path(@post) }
      format.json { head :ok }
    end
  end

  def toggle_comment
    @comment = Comment.find(params[:id])
    Like.toggle(user: current_user, likeable: @comment)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: post_path(@comment.post) }
      format.json { head :ok }
    end
  end

  # Begenen kullanicilarin isim+foto+id listesi (profil linki icin).
  def post_likers
    @post = Post.find(params[:id])
    likers = User.where(id: Like.where(likeable: @post).select(:user_id)).order(:name)

    respond_to do |format|
      format.html { render partial: "likes/likers", locals: { users: likers }, layout: false }
      format.json { render json: users_json(likers) }
    end
  end

  private

  def users_json(users)
    users.map { |u| { id: u.id, name: u.name, avatar_url: u.avatar_url } }
  end
end
