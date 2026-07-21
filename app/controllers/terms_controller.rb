class TermsController < ApplicationController
  before_action :require_login

  def show
  end

  def accept
    current_user.update!(terms_accepted_at: Time.current)
    redirect_to root_path, notice: "Kurallar onaylandı, hoş geldin."
  end
end
