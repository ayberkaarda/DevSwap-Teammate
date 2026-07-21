class SavedPostsController < ApplicationController
  before_action :require_login

  def toggle
    @post = Post.find(params[:id])
    SavedPost.toggle(user: current_user, post: @post)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: post_path(@post) }
      format.json { head :ok }
    end
  end
end
