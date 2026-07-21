class WarningsController < ApplicationController
  before_action :require_staff

  def create
    target = User.find(params[:user_id])
    warning = UserWarning.new(user: target, issued_by: current_user, reason: params[:reason])

    if warning.save
      redirect_back(fallback_location: root_path, notice: "Uyarı gönderildi.")
    else
      redirect_back(fallback_location: root_path, alert: warning.errors.full_messages.to_sentence)
    end
  end
end
