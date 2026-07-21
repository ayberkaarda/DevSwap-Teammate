class EscalationsController < ApplicationController
  before_action :require_staff

  def create
    target = User.find(params[:target_user_id])
    escalation = Escalation.new(reported_by: current_user, target_user: target, description: params[:description])
    escalation.evidence_photo.attach(params[:evidence_photo]) if params[:evidence_photo].present?

    if escalation.save
      redirect_back(fallback_location: root_path, notice: "Admin'e bildirildi.")
    else
      redirect_back(fallback_location: root_path, alert: escalation.errors.full_messages.to_sentence)
    end
  end
end
