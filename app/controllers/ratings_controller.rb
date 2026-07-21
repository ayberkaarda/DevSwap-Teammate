class RatingsController < ApplicationController
  before_action :require_login

  def create
    room = ChatRoom.find_by!(slug: params[:room_slug])
    return head(:forbidden) unless room.private? && room.participant?(current_user)
    return head(:forbidden) unless room.ended?
    return redirect_to room_path(room.slug), alert: "Zaten değerlendirdin." if room.rated_by?(current_user)

    rated_user = room.other_participant(current_user)
    rating = Rating.new(
      rater: current_user,
      rated_user: rated_user,
      chat_room: room,
      score: params[:score],
      note: params[:note]
    )

    if rating.save
      redirect_to room_path(room.slug), notice: "Değerlendirmen kaydedildi."
    else
      redirect_to room_path(room.slug), alert: rating.errors.full_messages.to_sentence
    end
  end
end
