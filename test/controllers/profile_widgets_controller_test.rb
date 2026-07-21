require "test_helper"

class ProfileWidgetsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "reorder current_user'in kendi widget'larinin pozisyonlarini gunceller" do
    user = User.create!(name: "Duzenleyen", provider: "github", uid: "pwc-1", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    w1 = ProfileWidget.create!(user: user, widget_type: "identity", position_x: 0, position_y: 0, width: 4, height: 3)
    w2 = ProfileWidget.create!(user: user, widget_type: "teaching_skills", position_x: 4, position_y: 0, width: 8, height: 3)

    patch reorder_profile_widgets_path, params: {
      widgets: [
        { id: w1.id, position_x: 2, position_y: 5, width: 6, height: 2 },
        { id: w2.id, position_x: 8, position_y: 1, width: 3, height: 4 }
      ]
    }

    assert_response :ok

    w1.reload
    assert_equal [ 2, 5, 6, 2 ], [ w1.position_x, w1.position_y, w1.width, w1.height ]
    w2.reload
    assert_equal [ 8, 1, 3, 4 ], [ w2.position_x, w2.position_y, w2.width, w2.height ]
  end

  test "reorder baskasinin widget id'sini iceren istegi 422 ile reddeder ve hicbir sey degistirmez" do
    user = User.create!(name: "Saldirgan", provider: "github", uid: "pwc-2", terms_accepted_at: Time.current)
    victim = User.create!(name: "Kurban", provider: "github", uid: "pwc-3", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    mine = ProfileWidget.create!(user: user, widget_type: "identity", position_x: 0, position_y: 0, width: 4, height: 3)
    theirs = ProfileWidget.create!(user: victim, widget_type: "identity", position_x: 0, position_y: 0, width: 4, height: 3)

    patch reorder_profile_widgets_path, params: {
      widgets: [
        { id: mine.id, position_x: 5, position_y: 5, width: 6, height: 6 },
        { id: theirs.id, position_x: 9, position_y: 9, width: 2, height: 2 }
      ]
    }

    assert_response :unprocessable_entity

    # Transaction rollback: sahip olunan widget bile degismemeli
    mine.reload
    assert_equal [ 0, 0, 4, 3 ], [ mine.position_x, mine.position_y, mine.width, mine.height ]
    theirs.reload
    assert_equal [ 0, 0, 4, 3 ], [ theirs.position_x, theirs.position_y, theirs.width, theirs.height ]
  end

  test "update kendi widget'inin visible ve font_scale degerlerini degistirir" do
    user = User.create!(name: "Ayarci", provider: "github", uid: "pwc-4", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    widget = ProfileWidget.create!(user: user, widget_type: "github_repos", visible: true, font_scale: 1.0)

    patch profile_widget_path(widget), params: {
      profile_widget: { visible: false, font_scale: 1.5 }
    }

    assert_response :ok

    widget.reload
    assert_equal false, widget.visible
    assert_equal 1.5, widget.font_scale.to_f
  end

  test "update baskasinin widget'ini degistiremez (422)" do
    user = User.create!(name: "Yetkisiz", provider: "github", uid: "pwc-5", terms_accepted_at: Time.current)
    victim = User.create!(name: "Sahip", provider: "github", uid: "pwc-6", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    widget = ProfileWidget.create!(user: victim, widget_type: "github_repos", visible: true, font_scale: 1.0)

    patch profile_widget_path(widget), params: {
      profile_widget: { visible: false, font_scale: 2.0 }
    }

    assert_response :unprocessable_entity

    widget.reload
    assert_equal true, widget.visible
    assert_equal 1.0, widget.font_scale.to_f
  end

  test "update gecersiz font_scale ile 422 doner" do
    user = User.create!(name: "Hatali", provider: "github", uid: "pwc-7", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    widget = ProfileWidget.create!(user: user, widget_type: "github_repos", font_scale: 1.0)

    patch profile_widget_path(widget), params: {
      profile_widget: { font_scale: 5.0 }
    }

    assert_response :unprocessable_entity
    widget.reload
    assert_equal 1.0, widget.font_scale.to_f
  end

  test "giris yapmamis kullanici reorder yapamaz" do
    user = User.create!(name: "Sahip", provider: "github", uid: "pwc-8", terms_accepted_at: Time.current)
    widget = ProfileWidget.create!(user: user, widget_type: "identity")

    patch reorder_profile_widgets_path, params: {
      widgets: [ { id: widget.id, position_x: 1, position_y: 1, width: 2, height: 2 } ]
    }

    assert_redirected_to root_path
  end

  test "reset current_user'in profil yerlesimini varsayilana sifirlar" do
    user = User.create!(name: "Sifirlayici", provider: "github", uid: "pwc-9", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    ProfileWidget.seed_defaults_for(user)
    # Konum ızgara icinde kalmali (position_x + width <= 12); identity width=6.
    ProfileWidget.where(user: user).find_by(widget_type: "identity").update!(position_x: 2, position_y: 9)
    ProfileWidget.where(user: user).find_by(widget_type: "github_repos").destroy!

    post reset_profile_widgets_path

    assert_redirected_to public_profile_path(user)

    assert_equal 5, ProfileWidget.where(user: user).count
    assert_equal 0, ProfileWidget.where(user: user, position_x: 2, position_y: 9, widget_type: "identity").count
  end

  test "reorder izgara sinirini asan (position_x + width > 12) geometriyi 422 ile reddeder" do
    user = User.create!(name: "Tasan", provider: "github", uid: "pwc-overflow-1", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    widget = ProfileWidget.create!(user: user, widget_type: "identity", position_x: 0, position_y: 0, width: 4, height: 3)

    # x=8, w=6 => 14 > 12: kabul edilMEMELİ, kayit degismemeli.
    patch reorder_profile_widgets_path, params: {
      widgets: [ { id: widget.id, position_x: 8, position_y: 0, width: 6, height: 3 } ]
    }

    assert_response :unprocessable_entity
    widget.reload
    assert_equal [ 0, 0, 4, 3 ], [ widget.position_x, widget.position_y, widget.width, widget.height ]
  end

  test "giris yapmamis kullanici reset yapamaz" do
    user = User.create!(name: "Sahip", provider: "github", uid: "pwc-10", terms_accepted_at: Time.current)
    ProfileWidget.seed_defaults_for(user)

    post reset_profile_widgets_path

    assert_redirected_to root_path
    assert_equal 5, ProfileWidget.where(user: user).count
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
