require "test_helper"

class MessageReactionsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )
    get "/auth/github/callback"
  end

  def setup_data
    @user = User.create!(name: "MRC-U", provider: "github", uid: "mrc-u", terms_accepted_at: Time.current)
    @message = Message.create!(user: @user, chat_room: chat_rooms(:genel), body: "tepki icin mesaj")
  end

  test "gecerli emoji toggle on/off (public odada herkes katilimci)" do
    setup_data
    sign_in_via_github(@user)
    emoji = MessageReaction::ALLOWED_EMOJI.first

    assert_difference "MessageReaction.count", 1 do
      post toggle_message_reaction_path(@message), params: { emoji: emoji }
    end
    assert_response :no_content

    assert_difference "MessageReaction.count", -1 do
      post toggle_message_reaction_path(@message), params: { emoji: emoji }
    end
  end

  test "ayni emoji ikinci kez farkli hicbir sey yaratmaz (uniqueness constraint)" do
    setup_data
    sign_in_via_github(@user)
    emoji = MessageReaction::ALLOWED_EMOJI.first

    post toggle_message_reaction_path(@message), params: { emoji: emoji }
    assert_equal 1, MessageReaction.where(message: @message, emoji: emoji).count

    # Toggle tekrar → kaldirir (0), tekrar → ekler (1); asla 2 olmaz.
    post toggle_message_reaction_path(@message), params: { emoji: emoji }
    assert_equal 0, MessageReaction.where(message: @message, emoji: emoji).count
    post toggle_message_reaction_path(@message), params: { emoji: emoji }
    assert_equal 1, MessageReaction.where(message: @message, emoji: emoji).count
  end

  test "gecersiz emoji reddedilir (422)" do
    setup_data
    sign_in_via_github(@user)

    assert_no_difference "MessageReaction.count" do
      post toggle_message_reaction_path(@message), params: { emoji: "xxx" }
    end
    assert_response :unprocessable_entity
  end

  test "giris gerektirir" do
    setup_data
    assert_no_difference "MessageReaction.count" do
      post toggle_message_reaction_path(@message), params: { emoji: MessageReaction::ALLOWED_EMOJI.first }
    end
    assert_redirected_to root_path
  end

  test "private DM odasinda katilimci olmayan tepki veremez (403)" do
    owner = User.create!(name: "React DM Sahibi", provider: "github", uid: "react-dm-owner", terms_accepted_at: Time.current)
    peer = User.create!(name: "React DM Karsi", provider: "github", uid: "react-dm-peer", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(owner, peer)
    dm_message = Message.create!(user: owner, chat_room: dm, body: "gizli mesaj")

    outsider = User.create!(name: "React Yabanci", provider: "github", uid: "react-out", terms_accepted_at: Time.current)
    sign_in_via_github(outsider)

    assert_no_difference "MessageReaction.count" do
      post toggle_message_reaction_path(dm_message), params: { emoji: MessageReaction::ALLOWED_EMOJI.first }
    end
    assert_response :forbidden
  end
end
