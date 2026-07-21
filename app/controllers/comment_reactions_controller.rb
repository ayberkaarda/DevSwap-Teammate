class CommentReactionsController < ApplicationController
  before_action :require_login

  def toggle
    @comment = Comment.find(params[:id])
    emoji = params[:emoji].to_s

    unless CommentReaction::ALLOWED_EMOJI.include?(emoji)
      return respond_to do |format|
        format.html { redirect_back fallback_location: post_path(@comment.post), alert: "Geçersiz emoji." }
        format.json { head :unprocessable_entity }
      end
    end

    CommentReaction.toggle(user: current_user, comment: @comment, emoji: emoji)

    respond_to do |format|
      format.turbo_stream { render "likes/toggle_comment" }
      format.html { redirect_back fallback_location: post_path(@comment.post) }
      format.json { head :ok }
    end
  end
end
