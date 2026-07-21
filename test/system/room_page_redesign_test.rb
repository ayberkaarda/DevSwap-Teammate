require "application_system_test_case"

# Faz 32d — Standalone /rooms/:slug redesign uctan uca dogrulamasi.
#   1. Sayfa koyu terminal chrome'u (mac/windows skin gecis butonu) ile render edilir.
#   2. Sag kenar cubugu kullanicinin DM kisilerini (isim) listeler.
#   3. Kenar cubugu arama kutusu client-side (Stimulus) substring filtresi uygular.
#
# use_transactional_tests = false (sistem testleri ayri tarayici prosesi kullanir);
# olusturulan tum veri teardown'da elle temizlenir.
class RoomPageRedesignTest < ApplicationSystemTestCase
  MOCK_UID = "room-redesign-viewer"

  def setup
    OmniAuth.config.test_mode = true

    @viewer = User.create!(name: "Redesign Viewer", provider: "github", uid: "redesign-1", terms_accepted_at: Time.current)
    @alpha  = User.create!(name: "Kisi Alfa", provider: "github", uid: "redesign-a", terms_accepted_at: Time.current)
    @beta   = User.create!(name: "Kisi Beta", provider: "github", uid: "redesign-b", terms_accepted_at: Time.current)

    @public_room = ChatRoom.public_rooms.first || ChatRoom.create!(name: "Genel", slug: "redesign-public", private: false, position: 1)
    @dm_alpha = ChatRoom.find_or_create_dm_between(@viewer, @alpha)
    @dm_beta  = ChatRoom.find_or_create_dm_between(@viewer, @beta)
    Message.create!(chat_room: @dm_alpha, user: @alpha, body: "alfa mesaji")
    Message.create!(chat_room: @dm_beta, user: @beta, body: "beta mesaji")

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

    [ @dm_alpha, @dm_beta ].each { |r| r&.messages&.destroy_all }
    DismissedConversation.where(user_id: @viewer&.id).destroy_all
    @dm_alpha&.destroy
    @dm_beta&.destroy
    @viewer&.destroy
    @alpha&.destroy
    @beta&.destroy
  end

  test "standalone oda sayfasi koyu chrome + DM kenar cubugu render eder ve arama filtreler" do
    visit "/auth/github/callback"
    visit "/rooms/#{@public_room.slug}"

    # 1. Koyu terminal chrome'unun skin gecis butonu (terminal-skin controller) render edilmis olmali.
    assert_selector "button[data-controller='terminal-skin']"

    # 2. Kenar cubugu her iki DM kisisini de listelemeli.
    assert_selector "[data-controller='contact-search']"
    within "[data-controller='contact-search']" do
      assert_text @alpha.name
      assert_text @beta.name
    end

    # 3. Arama kutusuna "Beta" yazilinca sadece eslesen kisi kalmali (client-side).
    find("[data-contact-search-target='input']").set("Beta")

    within "[data-controller='contact-search']" do
      assert_text @beta.name
      assert_no_text @alpha.name
    end
  end
end
