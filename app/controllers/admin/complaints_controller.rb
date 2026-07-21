class Admin::ComplaintsController < ApplicationController
  before_action :require_admin
  before_action :set_complaint, only: [ :mark_reviewed, :dismiss, :mark_actioned, :destroy ]

  PER_PAGE = 25

  def index
    @filter = params[:status].to_s
    scope = Complaint.includes(:reported_by, :target_user).order(created_at: :desc)
    scope = scope.where(status: @filter) if Complaint::STATUSES.include?(@filter)

    @page = [ params[:page].to_i, 1 ].max
    @total = scope.count
    @complaints = scope.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    @next_page = (@total > @page * PER_PAGE) ? @page + 1 : nil
  end

  def mark_reviewed
    @complaint.update!(status: "reviewed")
    ActivityLog.record!(current_user, "admin_complaint_reviewed", "#{current_user.name} bir şikayeti incelendi olarak işaretledi (##{@complaint.id}).", metadata: { target_id: @complaint.id })
    redirect_to admin_complaints_path(status: params[:status]), notice: "Şikayet incelendi olarak işaretlendi."
  end

  def dismiss
    @complaint.update!(status: "dismissed")
    ActivityLog.record!(current_user, "admin_complaint_dismissed", "#{current_user.name} bir şikayeti reddetti (##{@complaint.id}).", metadata: { target_id: @complaint.id })
    redirect_to admin_complaints_path(status: params[:status]), notice: "Şikayet reddedildi."
  end

  def mark_actioned
    @complaint.update!(status: "actioned")
    ActivityLog.record!(current_user, "admin_complaint_actioned", "#{current_user.name} bir şikayet için işlem yaptı (##{@complaint.id}).", metadata: { target_id: @complaint.id })
    redirect_to admin_complaints_path(status: params[:status]), notice: "Şikayet işlem yapıldı olarak işaretlendi."
  end

  def destroy
    reporter_name = @complaint.reported_by&.name
    reporter_id = @complaint.reported_by&.id
    target_name = @complaint.target_user&.name
    target_id = @complaint.target_user&.id
    complaint_id = @complaint.id
    @complaint.destroy!
    ActivityLog.record!(current_user, "admin_complaint_deleted", "#{current_user.name} bir şikayeti kalıcı olarak sildi (##{complaint_id}, bildiren: #{reporter_name}, hedef: #{target_name}).", metadata: { complaint_id: complaint_id, target_user_id: target_id, reported_by_id: reporter_id })
    redirect_to admin_complaints_path(status: params[:status]), notice: "Şikayet kalıcı olarak silindi."
  end

  private

  def set_complaint
    @complaint = Complaint.find(params[:id])
  end
end
