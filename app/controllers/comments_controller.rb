class CommentsController < ApplicationController
  before_action :require_login
  before_action :require_not_muted, only: [ :create ]

  def create
    post = Post.find(params[:post_id])
    comment = post.comments.new(content: params[:content], user: current_user)
    comment.parent_id = params[:parent_id] if params[:parent_id].present?

    if comment.save
      redirect_back fallback_location: post_path(post), notice: "Yorum eklendi."
    else
      redirect_back fallback_location: post_path(post), alert: comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    comment = Comment.find(params[:id])
    post = comment.post

    unless comment.user_id == current_user.id || current_user.staff?
      return redirect_back fallback_location: post_path(post), alert: "Bu yorumu silme yetkin yok."
    end

    # Silme olayi admin telemetri log'una dusmeli (backlog: silme islemleri loglanmali).
    ActivityLog.record!(
      current_user, "comment_deleted",
      "#{current_user.name} bir yorumu sildi (post ##{post.id}): \"#{comment.content.to_s.truncate(80)}\""
    )

    comment.destroy
    redirect_back fallback_location: post_path(post), notice: "Yorum silindi."
  end
end
