require "test_helper"

class BlocksControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "giris yapmis kullanici baskasini engelleyebilir" do
    viewer = User.create!(name: "Blocker", provider: "github", uid: "bl-1", terms_accepted_at: Time.current)
    target = User.create!(name: "Blocked", provider: "github", uid: "bl-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_difference "Block.count", 1 do
      post blocks_path, params: { blocked_id: target.id }
    end
    assert viewer.reload.blocking?(target)
  end

  test "kendini engelleyemez" do
    viewer = User.create!(name: "SelfBlock", provider: "github", uid: "bl-3", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_no_difference "Block.count" do
      post blocks_path, params: { blocked_id: viewer.id }
    end
  end

  test "engel kaldirilabilir (destroy)" do
    viewer = User.create!(name: "Unblocker", provider: "github", uid: "bl-4", terms_accepted_at: Time.current)
    target = User.create!(name: "WasBlocked", provider: "github", uid: "bl-5", terms_accepted_at: Time.current)
    block = viewer.blocks_made.create!(blocked: target)
    sign_in_via_github(viewer)

    assert_difference "Block.count", -1 do
      delete block_path(block.id)
    end
    assert_not viewer.reload.blocking?(target)
  end

  test "baskasinin blogunu silemez" do
    owner = User.create!(name: "Owner", provider: "github", uid: "bl-6", terms_accepted_at: Time.current)
    other = User.create!(name: "Other", provider: "github", uid: "bl-7", terms_accepted_at: Time.current)
    target = User.create!(name: "Target", provider: "github", uid: "bl-8", terms_accepted_at: Time.current)
    block = owner.blocks_made.create!(blocked: target)
    sign_in_via_github(other)

    assert_no_difference "Block.count" do
      delete block_path(block.id)
    end
  end

  test "giris yapmamis kullanici engelleyemez" do
    target = User.create!(name: "NoAuthTarget", provider: "github", uid: "bl-9", terms_accepted_at: Time.current)
    assert_no_difference "Block.count" do
      post blocks_path, params: { blocked_id: target.id }
    end
    assert_redirected_to root_path
  end

  private

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )
    get "/auth/github/callback"
  end
end
