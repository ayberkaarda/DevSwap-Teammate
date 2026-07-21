require "application_system_test_case"

# Faz 32c — Chat UI (Facebook Messenger tarzi DM balonlari + tiklanabilir kullanici
# adlari + mesaj duzenle/sil + emoji tepkileri) uctan uca dogrulamasi.
#
# ActionCable canli guncellemeleri (message_edited / message_deleted /
# message_reaction) icin: test ortaminin varsayilan `test` cable adaptoru yayinlari
# gercekten tarayiciya ULASTIRMAZ. Sistem testleri Puma'yi ayni proses icinde
# calistirdigindan, ayni-proses `async` adaptorune gecerek yayinlarin tarayici
# aboneliklerine gercekten dusmesini sagliyoruz (teardown'da geri aliniyor).
class ChatUiTest < ApplicationSystemTestCase
  MOCK_UID = "chat-ui-test-viewer"

  def setup
    OmniAuth.config.test_mode = true

    # Canli yayinlarin gercekten tarayiciya ulasmasi icin async cable adaptorune gec.
    @original_cable = ActionCable.server.config.cable
    ActionCable.server.config.cable = { "adapter" => "async" }
    ActionCable.server.restart

    @viewer = User.create!(name: "Chat UI Viewer", provider: "github", uid: "chat-ui-1", terms_accepted_at: Time.current)
    @other  = User.create!(name: "Chat UI Partner", provider: "github", uid: "chat-ui-2", terms_accepted_at: Time.current)
    @third  = User.create!(name: "Chat UI Ucuncu", provider: "github", uid: "chat-ui-3", terms_accepted_at: Time.current)

    # DashboardController genel (private olmayan) bir ChatRoom bekler.
    @public_room = ChatRoom.public_rooms.first || ChatRoom.create!(name: "Genel", slug: "chat-ui-public", private: false, position: 1)

    # Iki ayri DM: birinin popup'i SADECE kendi konusmasini gostermeli.
    @dm_room = ChatRoom.find_or_create_dm_between(@viewer, @other)
    @unread  = Message.create!(chat_room: @dm_room, user: @other, body: "DM_MESAJI_PARTNER_2026")
    @other_dm = ChatRoom.find_or_create_dm_between(@viewer, @third)
    Message.create!(chat_room: @other_dm, user: @third, body: "UCUNCU_DM_MESAJI_2026")

    DashboardWidget.seed_defaults_for(@viewer) if @viewer.dashboard_widgets.none?

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: MOCK_UID,
      info: { name: @viewer.name, email: @viewer.email, nickname: MOCK_UID, image: nil },
      credentials: { token: "test-token" }
    )
    @viewer.update!(provider: "github", uid: MOCK_UID)
  end

  def teardown
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil

    ActionCable.server.config.cable = @original_cable
    ActionCable.server.restart

    @dm_room&.messages&.destroy_all
    @other_dm&.messages&.destroy_all
    @public_room&.messages&.where(user_id: [ @viewer&.id, @other&.id, @third&.id ].compact)&.destroy_all
    @viewer&.reload&.dashboard_widgets&.destroy_all
    @dm_room&.destroy
    @other_dm&.destroy
    @viewer&.destroy
    @other&.destroy
    @third&.destroy
  end

  test "minimal DM popup SADECE o konusmayi ve karsi katilimcinin ismini gosterir; baska DM gorunmez" do
    @viewer.dashboard_widgets.find_by(widget_type: "chatbox").update!(visible: false)

    visit "/auth/github/callback"
    visit "/"

    assert_selector "[data-controller='minimal-dm']"

    # @other ile olan DM balonuna tikla → popup yukari acilir.
    find("button[data-room-slug='#{@dm_room.slug}']").click

    # Popup SADECE bu konusmayi tasimali (dashboard'in geri kalanindaki kesif
    # kartlari degil) — bu yuzden tum icerik/negatif iddialar popup'a scope'lanir.
    within "[data-minimal-dm-target='popup']" do
      assert_selector "#chat-messages"
      assert_text @other.name
      assert_text "DM_MESAJI_PARTNER_2026"

      # Diger DM (ucuncu kisi) veya oda sekmeleri popup ICINDE GORUNMEMELI.
      assert_no_selector "[aria-label='Sohbet odaları']"
      assert_no_text "UCUNCU_DM_MESAJI_2026"
      assert_no_text @third.name

      # Partner ismi profiline giden link olmali.
      assert_selector "a[href='#{public_profile_path(@other.id)}']", text: @other.name
    end
  end

  test "mesajdaki kullanici adi profiline goturur; kendi mesaji duzenlenebilir, silinebilir and emoji tepkisi alir" do
    my_message = Message.create!(chat_room: @public_room, user: @viewer, body: "BENIM_ORIJINAL_MESAJIM")

    visit "/auth/github/callback"
    visit "/"

    assert_selector "#msg-#{my_message.id}"

    # 1) EMOJI TEPKISI: picker'i ac, bir emoji sec → canli sayac cip'i belirir.
    find("#msg-#{my_message.id}").hover
    within "#msg-#{my_message.id}" do
      tepki_butonu = find("button[title='Tepki ver']", visible: :all)
      execute_script("arguments[0].click();", tepki_butonu)

      emoji_butonu = find("button[data-emoji='🔥']", visible: :all)
      execute_script("arguments[0].click();", emoji_butonu)
    end
    assert_selector "#msg-reactions-#{my_message.id} .reaction-chip", text: "🔥"

    # 2) DUZENLEME: satir-ici forma gec, metni degistir, kaydet → canli govde + (düzenlendi).
    find("#msg-#{my_message.id}").hover
    within "#msg-#{my_message.id}" do
      duzenle_butonu = find(:link_or_button, "düzenle", visible: :all)
      execute_script("arguments[0].click();", duzenle_butonu)
    end
    find("#msg-#{my_message.id} [data-chat-message-target='editInput']").set("DUZENLENMIS_MESAJ_METNI")
    within "#msg-#{my_message.id}" do
      click_on "Kaydet"
    end
    assert_selector "#msg-#{my_message.id}", text: "DUZENLENMIS_MESAJ_METNI"
    assert_selector "#msg-#{my_message.id}", text: "(düzenlendi)"

    # 3) SILME: onayla → canli olarak DOM'dan kalkar + ActivityLog'a duser.
    find("#msg-#{my_message.id}").hover
    assert_difference -> { ActivityLog.where(action_type: "message_deleted").count }, 1 do
      accept_confirm do
        within "#msg-#{my_message.id}" do
          sil_butonu = find(:link_or_button, "sil", visible: :all)
          execute_script("arguments[0].click();", sil_butonu)
        end
      end
      assert_no_selector "#msg-#{my_message.id}"
    end

    # 4) KULLANICI ADI LINKI: silinen mesaj yerine yeni bir mesaj yok; ancak
    #    server-render link bicimini yeni bir mesajla dogrula.
    link_message = Message.create!(chat_room: @public_room, user: @other, body: "LINK_TEST_MESAJI")
    visit "/"
    assert_selector "#msg-#{link_message.id} a[href='#{public_profile_path(@other.id)}']", text: @other.name
  ensure
    ActivityLog.where(action_type: "message_deleted").delete_all
  end
end
