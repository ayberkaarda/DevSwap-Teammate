require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "giris yapmadan mesaj olusturulamaz" do
    assert_no_difference "Message.count" do
      post messages_path, params: { message: { body: "izinsiz" } }
    end
    assert_redirected_to root_path
  end

  test "room param'i ile mesaj dogru odaya baglanir" do
    viewer = User.create!(name: "Mesaj Gonderen", provider: "github", uid: "msg-1", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_difference "Message.count", 1 do
      post messages_path, params: { message: { body: "backend selam" }, room: chat_rooms(:genel).slug }
    end

    assert_response :no_content
    assert_equal chat_rooms(:genel), Message.order(:created_at).last.chat_room
  end

  test "room param'i olmadan mesaj varsayilan (ilk) odaya baglanir" do
    viewer = User.create!(name: "Varsayilan Oda", provider: "github", uid: "msg-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_difference "Message.count", 1 do
      post messages_path, params: { message: { body: "odasiz mesaj" } }
    end

    assert_response :no_content
    assert_equal ChatRoom.order(:position).first, Message.order(:created_at).last.chat_room
  end

  test "gecersiz room slug ile mesaj varsayilan odaya duser" do
    viewer = User.create!(name: "Gecersiz Oda", provider: "github", uid: "msg-3", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_difference "Message.count", 1 do
      post messages_path, params: { message: { body: "kayip mesaj" }, room: "olmayan-oda" }
    end

    assert_response :no_content
    assert_equal ChatRoom.order(:position).first, Message.order(:created_at).last.chat_room
  end

  test "bos govde ile mesaj olusturulmaz" do
    viewer = User.create!(name: "Bos Govde", provider: "github", uid: "msg-4", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_no_difference "Message.count" do
      post messages_path, params: { message: { body: "   " }, room: chat_rooms(:genel).slug }
    end

    assert_response :no_content
  end

  test "katilimci olmayan kullanici private DM odasina mesaj postalayinca 403 alir" do
    owner = User.create!(name: "Mesaj DM Sahibi", provider: "github", uid: "mdm-owner", terms_accepted_at: Time.current)
    peer = User.create!(name: "Mesaj DM Karsi", provider: "github", uid: "mdm-peer", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(owner, peer)

    outsider = User.create!(name: "Mesaj DM Yabanci", provider: "github", uid: "mdm-out", terms_accepted_at: Time.current)
    sign_in_via_github(outsider)

    assert_no_difference "Message.count" do
      post messages_path, params: { message: { body: "izinsiz DM" }, room: dm.slug }
    end

    assert_response :forbidden
  end

  test "katilimci private DM odasina mesaj postalayabilir" do
    owner = User.create!(name: "Mesaj DM Ic", provider: "github", uid: "mdm-in", terms_accepted_at: Time.current)
    peer = User.create!(name: "Mesaj DM Ic 2", provider: "github", uid: "mdm-in2", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(owner, peer)

    sign_in_via_github(owner)

    assert_difference "Message.count", 1 do
      post messages_path, params: { message: { body: "gizli selam" }, room: dm.slug }
    end

    assert_response :no_content
    assert_equal dm, Message.order(:created_at).last.chat_room
  end

  test "susturulmus kullanici mesaj gonderemez" do
    viewer = User.create!(name: "Susturulan", provider: "github", uid: "msg-mute", terms_accepted_at: Time.current)
    staff = User.create!(name: "Mod", provider: "github", uid: "msg-mod", role: "moderator", terms_accepted_at: Time.current)
    Mute.create!(user: viewer, muted_by: staff, muted_until: 1.hour.from_now, active: true)
    sign_in_via_github(viewer)

    assert_no_difference "Message.count" do
      post messages_path, params: { message: { body: "susturulmusken mesaj" }, room: chat_rooms(:genel).slug }
    end

    assert_redirected_to root_path
  end

  # --- Faz 32c: mesaj duzenleme ---

  test "mesaj sahibi kendi mesajini duzenleyebilir ve edited_at dolar" do
    author = User.create!(name: "Duzenleyen", provider: "github", uid: "edit-author", terms_accepted_at: Time.current)
    message = Message.create!(user: author, chat_room: chat_rooms(:genel), body: "eski govde")
    sign_in_via_github(author)

    patch message_path(message), params: { message: { body: "yeni govde" } }

    assert_response :no_content
    message.reload
    assert_equal "yeni govde", message.body
    assert message.edited?
  end

  test "baskasinin mesajini duzenlemek 403 doner ve degismez" do
    author = User.create!(name: "Sahip", provider: "github", uid: "edit-owner2", terms_accepted_at: Time.current)
    message = Message.create!(user: author, chat_room: chat_rooms(:genel), body: "dokunma")

    outsider = User.create!(name: "Yabanci Duzenleyen", provider: "github", uid: "edit-out", terms_accepted_at: Time.current)
    sign_in_via_github(outsider)

    patch message_path(message), params: { message: { body: "ele gecirdim" } }

    assert_response :forbidden
    assert_equal "dokunma", message.reload.body
    assert_not message.edited?
  end

  test "staff bile baskasinin mesajini DUZENLEYEMEZ (yalniz sahip)" do
    author = User.create!(name: "Yazar", provider: "github", uid: "edit-a3", terms_accepted_at: Time.current)
    message = Message.create!(user: author, chat_room: chat_rooms(:genel), body: "sahibinindir")
    admin = User.create!(name: "Admin Duz", provider: "github", uid: "edit-admin", role: "admin", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    patch message_path(message), params: { message: { body: "admin yazdi" } }

    assert_response :forbidden
    assert_equal "sahibinindir", message.reload.body
  end

  test "mesaj duzenleme admin telemetri log'una dusuyor" do
    author = User.create!(name: "Loglu Duzenleyen", provider: "github", uid: "edit-log", terms_accepted_at: Time.current)
    message = Message.create!(user: author, chat_room: chat_rooms(:genel), body: "orijinal")
    sign_in_via_github(author)

    assert_difference -> { ActivityLog.where(action_type: "message_edited").count }, 1 do
      patch message_path(message), params: { message: { body: "guncel" } }
    end
  end

  test "bos govde ile duzenleme 422 doner ve degismez" do
    author = User.create!(name: "Bos Duzenleyen", provider: "github", uid: "edit-blank", terms_accepted_at: Time.current)
    message = Message.create!(user: author, chat_room: chat_rooms(:genel), body: "dolu")
    sign_in_via_github(author)

    patch message_path(message), params: { message: { body: "   " } }

    assert_response :unprocessable_entity
    assert_equal "dolu", message.reload.body
  end

  # --- Faz 32c: mesaj silme ---

  test "mesaj sahibi kendi mesajini silebilir ve log'a duser" do
    author = User.create!(name: "Silen Sahip", provider: "github", uid: "del-owner", terms_accepted_at: Time.current)
    message = Message.create!(user: author, chat_room: chat_rooms(:genel), body: "silinecek govde")
    sign_in_via_github(author)

    assert_difference -> { ActivityLog.where(action_type: "message_deleted").count }, 1 do
      assert_difference "Message.count", -1 do
        delete message_path(message)
      end
    end
    assert_response :no_content
  end

  test "staff (admin) baskasinin mesajini silebilir" do
    author = User.create!(name: "Silinen Yazar", provider: "github", uid: "del-a2", terms_accepted_at: Time.current)
    message = Message.create!(user: author, chat_room: chat_rooms(:genel), body: "mod silsin")
    admin = User.create!(name: "Silen Admin", provider: "github", uid: "del-admin", role: "admin", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "Message.count", -1 do
      delete message_path(message)
    end
    assert_response :no_content
  end

  test "yetkisiz kullanici baskasinin mesajini silemez (403)" do
    author = User.create!(name: "Korunan Yazar", provider: "github", uid: "del-a3", terms_accepted_at: Time.current)
    message = Message.create!(user: author, chat_room: chat_rooms(:genel), body: "silinemez")
    outsider = User.create!(name: "Silme Yabancisi", provider: "github", uid: "del-out", terms_accepted_at: Time.current)
    sign_in_via_github(outsider)

    assert_no_difference "Message.count" do
      delete message_path(message)
    end
    assert_response :forbidden
  end

  private

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )

    get "/auth/github/callback"
  end
end
