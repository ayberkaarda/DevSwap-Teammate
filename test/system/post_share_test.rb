require "application_system_test_case"

# "Gonder" (post'u DM olarak paylas) akisinin gercek tarayicida uctan uca
# calistigini dogrular. Backend izole controller testlerinde (bkz.
# test/controllers/post_shares_controller_test.rb) zaten dogrulanmis; bu test
# JS + Turbo + dinamik DOM (dialog icine innerHTML ile enjekte edilen form)
# kablolamasini kapsar.
class PostShareTest < ApplicationSystemTestCase
  def setup
    OmniAuth.config.test_mode = true

    @sender = User.create!(name: "Share Sender", provider: "github",
                            uid: "post-share-sender", terms_accepted_at: Time.current)
    @recipient = User.create!(name: "Share Recipient", provider: "github",
                               uid: "post-share-recipient", terms_accepted_at: Time.current)
    ChatRoom.find_or_create_dm_between(@sender, @recipient)

    @post = Post.create!(content: "SHARE_TEST_POSTU", user: @sender)

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: @sender.uid,
      info: { name: @sender.name, email: @sender.email, nickname: @sender.uid, image: nil },
      credentials: { token: "test-token" }
    )
  end

  def teardown
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
    cleanup_share_user(@sender)
    cleanup_share_user(@recipient)
  end

  # PostShare/ChatRoom/Message satirlarini (FK sirasina saygi gostererek) ve
  # ardindan kullaniciyi temizler. Bir testte olusan yeni DM odalari (or.
  # arama testindeki "stranger" odasi) da kullanicinin ChatRoom'lari
  # uzerinden yakalanir, sabit bir alici varsaymaz.
  def cleanup_share_user(user)
    return unless user

    PostShare.where(user: user).destroy_all
    PostShare.where(recipient: user).destroy_all
    ChatRoom.dm_rooms_for(user).destroy_all
    Post.where(user: user).destroy_all
    user.destroy
  end

  test "Gonder butonuyla post gercekten DM olarak gonderilir" do
    visit "/auth/github/callback"
    visit posts_path

    within "#post_#{@post.id}_interactions" do
      find("button[aria-label='Gönder']").click
    end

    assert_selector "dialog[open] form"

    within "dialog[open]" do
      assert_text @recipient.name
      within "li", text: @recipient.name do
        click_on "Gönder"
      end
    end

    assert_text "#{@recipient.name} kişisine gönderildi"

    logs = page.driver.browser.logs.get(:browser).map(&:message)
    severe_logs = page.driver.browser.logs.get(:browser).select { |l| l.level == "SEVERE" }
    assert_empty severe_logs, "Konsolda hata var:\n#{severe_logs.map(&:message).join("\n")}"

    room = ChatRoom.find_or_create_dm_between(@sender, @recipient)
    assert room.messages.exists?, "Gonder tiklaninca gercekten bir DM mesaji olusmali"
    assert PostShare.exists?(user: @sender, post: @post, recipient: @recipient)
  end

  test "arama kutusuna yazsa bile DAHA ONCE DM'LESILMEMIS biri BULUNAMAZ / gonderilemez" do
    stranger = User.create!(name: "Never Dmed Stranger", provider: "github",
                             uid: "post-share-stranger", terms_accepted_at: Time.current)

    visit "/auth/github/callback"
    visit posts_path

    within "#post_#{@post.id}_interactions" do
      find("button[aria-label='Gönder']").click
    end

    assert_selector "dialog[open] form"
    within "dialog[open]" do
      assert_no_text stranger.name, wait: 1

      # Client-side filtre sadece zaten yuklenmis (DM partnerleri) satirlarda
      # calisir; sunucuya tekrar sorulmaz, stranger hicbir zaman gorunmez.
      fill_in "Kişi ara (herkeste arayabilirsin)...", with: "Never Dmed"
      assert_no_text stranger.name, wait: 1

      # Mevcut partner hala filtrelenebilir durumda (dogru davranisi dogrular).
      fill_in "Kişi ara (herkeste arayabilirsin)...", with: ""
      assert_text @recipient.name
    end

    assert_not ChatRoom.dm_rooms_for(@sender).any? { |r| r.other_participant(@sender) == stranger },
               "Hic DM'i olmayan biriyle post-paylasim uzerinden oda acilmamali"
    assert_not PostShare.exists?(user: @sender, post: @post, recipient: stranger)
  ensure
    cleanup_share_user(stranger)
  end
end
