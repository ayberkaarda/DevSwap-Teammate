class SessionsController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: :create,
    with: -> { redirect_to root_path, alert: "Çok fazla giriş denemesi yapıldı, biraz sonra tekrar dene." }

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_from_omniauth(auth)


    if BannedAccount.banned?(user.provider, user.uid)
      return redirect_to root_path, alert: "Bu GitHub hesabı yasaklandı."
    end

    session[:user_id] = user.id

    ActivityLog.record!(user, "login", "#{user.name} giriş yaptı.")


    if user.skills_last_scanned_at.nil? || user.skills_last_scanned_at < 1.hour.ago
      GithubScanJob.perform_later(user.id)
    end



    session[:user_id] = user.id


    redirect_to root_path, notice: "Hoş geldin, #{user.name}."
  end

  def destroy
    ActivityLog.record!(current_user, "logout", "#{current_user.name} çıkış yaptı.") if current_user

    reset_session
    redirect_to root_path, notice: "Çıkış yapıldı."
  end

  def failure
    redirect_to root_path, alert: "GitHub girişi başarısız oldu."
  end
end
