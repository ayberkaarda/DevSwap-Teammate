class GithubRepositoriesController < ApplicationController
  before_action :require_login

  def update
    repo = current_user.github_repositories.find_by(id: params[:id])
    return head(:not_found) unless repo

    repo.update(visible_on_profile: params[:visible_on_profile])
    head :no_content
  end
end
