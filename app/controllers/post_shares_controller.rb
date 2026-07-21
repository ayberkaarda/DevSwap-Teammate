class PostSharesController < ApplicationController
  before_action :require_login

  # "Gonder" — postu bir DM olarak gonderir. Bir PostShare kaydi olusturur VE
  # DM odasina bir Message birakir. PostShare satirlari gizlilik-hassas: bu
  # controller hicbir yerde alici LISTESI dondurmez.
  def create
    @post = Post.find(params[:id])
    recipient = User.find(params[:recipient_id])

    if recipient.id == current_user.id
      return respond_to do |format|
        format.turbo_stream { render_share_error("Kendine gönderemezsin.") }
        format.html { redirect_back fallback_location: post_path(@post), alert: "Kendine gönderemezsin." }
        format.json { head :unprocessable_entity }
      end
    end

    unless dm_partner_ids.include?(recipient.id)
      return respond_to do |format|
        format.turbo_stream { render_share_error("Bu kullanıcıya gönderemezsin.") }
        format.html { redirect_back fallback_location: post_path(@post), alert: "Bu kullanıcıya gönderemezsin." }
        format.json { head :unprocessable_entity }
      end
    end

    extra = params[:message].to_s.strip

    # Blok varsa ve onceden bir DM yoksa yeni DM acilamaz (bkz.
    # ChatRoom.find_or_create_dm_between). Boyle bir durumda paylasim reddedilir.
    # Not: recipient zaten mevcut bir DM partneri oldugu icin (yukaridaki guard)
    # bu cagri pratikte her zaman VAR OLAN odayi bulur, yeni oda ACMAZ; origin
    # varsayilani "direct" olarak kalir (asla "match" degil).
    room = ChatRoom.find_or_create_dm_between(current_user, recipient)
    if room.nil?
      return respond_to do |format|
        format.turbo_stream { render_share_error("Bu kullanıcıya gönderemezsin.") }
        format.html { redirect_back fallback_location: post_path(@post), alert: "Bu kullanıcıya gönderemezsin." }
        format.json { head :unprocessable_entity }
      end
    end

    ActiveRecord::Base.transaction do
      PostShare.create!(user: current_user, post: @post, recipient: recipient)
      Message.create!(user: current_user, chat_room: room, body: share_body(@post, extra))
    end

    respond_to do |format|
      format.turbo_stream { @share_notice = "#{recipient.name} kişisine gönderildi ✓" }
      format.html { redirect_back fallback_location: post_path(@post), notice: "Post gönderildi." }
      format.json { head :ok }
    end
  end

  # Gonderilebilecek kisiler: SADECE current_user'in KENDI mevcut DM
  # partnerleri. Arama kutusu artik client-side calisir (bkz.
  # share_controller.js#filter) — bu action `q` parametresini dikkate
  # ALMAZ, her zaman ayni kisitli listeyi doner. Hic DM'lesilmemis birine
  # post-paylasim uzerinden ulasilamaz; yeni sohbet normal "mesaj gonder"
  # akisindan baslatilmalidir. GIZLILIK: hicbir durumda bir postun PostShare
  # alicilari sizdirilmaz; yalnizca kullanici isimleri (zaten herkese acik) doner.
  def share_targets
    @post = Post.find(params[:id])
    targets = User.where(id: dm_partner_ids).order(:name).limit(30)

    respond_to do |format|
      format.html { render partial: "post_shares/targets", locals: { users: targets, post: @post }, layout: false }
      format.json { render json: targets.map { |u| { id: u.id, name: u.name, avatar_url: u.avatar_url } } }
    end
  end

  private

  def dm_partner_ids
    ChatRoom.dm_rooms_for(current_user)
            .map { |r| r.other_participant(current_user)&.id }
            .compact.uniq
  end

  def render_share_error(message)
    render turbo_stream: turbo_stream.append(
      "main-content",
      partial: "shared/toast",
      locals: { message: message, variant: :error }
    )
  end

  def share_body(post, extra)
    label = post.title.presence || post.content.to_s.truncate(80)
    body = "Bir post paylaştı: \"#{label}\" (#{post_path(post)})"
    body += "\n#{extra}" if extra.present?
    body
  end
end
