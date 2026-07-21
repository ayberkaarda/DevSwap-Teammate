require "application_system_test_case"

# Post akisi "golden path" uctan uca dogrulamasi: giris yap -> /posts'u ziyaret
# et -> compose UI'siyla post olustur -> akista gorun -> begen -> begeni sayaci
# guncellensin -> yeniden paylas -> repost sayaci guncellensin.
#
# test/controllers/posts_controller_test.rb, likes_controller_test.rb ve
# reposts_controller_test.rb bu etkilesimleri izole (Rack::Test) seviyede zaten
# kapsiyor (turbo_stream yanitlari dahil). Bu test onlari TEKRARLAMAZ; amac,
# gercek bir tarayicida JS + Turbo + controller kablolamasinin butun olarak
# calistigini yakalamaktir (izole controller testlerinin goremeyecegi
# entegrasyon kirilmalarini yakalamak icin).
class PostFeedGoldenPathTest < ApplicationSystemTestCase
  MOCK_UID = "post-feed-golden-path-user"

  def setup
    OmniAuth.config.test_mode = true

    @user = User.create!(
      name: "Golden Path Tester",
      provider: "github",
      uid: MOCK_UID,
      terms_accepted_at: Time.current
    )

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: MOCK_UID,
      info: { name: @user.name, email: @user.email, nickname: MOCK_UID, image: nil },
      credentials: { token: "test-token" }
    )
  end

  def teardown
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil

    # NOT: User modelinde `has_many :posts` bilerek tanimli degil (bkz.
    # post_tag_picker_test.rb'deki ayni not); temizligi dogrudan Post.where
    # uzerinden yapiyoruz.
    Post.where(user: @user).destroy_all if @user
    @user&.destroy
  end

  test "post olustur, akista gorun, begen ve yeniden paylas - sayaclar guncellenir" do
    visit "/auth/github/callback"
    visit posts_path

    assert_selector "#post-compose"

    within "#post-compose" do
      fill_in "content", with: "GOLDEN_PATH_TEST_POSTU"
      click_on "Yayınla"
    end

    assert_selector "#posts-list", text: "GOLDEN_PATH_TEST_POSTU"

    post = Post.where(user: @user).order(created_at: :desc).first
    assert_not_nil post

    within "#post_#{post.id}_interactions" do
      assert_selector "button[title='Beğenenleri gör']", text: "0"

      find("button[aria-label='Beğen']").click

      assert_selector "button[title='Beğenenleri gör']", text: "1"
    end

    assert post.likes.reload.exists?(user: @user)

    within "#post_#{post.id}_interactions" do
      find("button[aria-label='Yeniden paylaş']").click

      assert_selector "button[title='Yeniden paylaşanları gör']", text: "1"
    end

    assert post.reposts.reload.exists?(user: @user)
  end
end
