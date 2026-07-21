require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "has many skills through user_skills" do
    assert_includes users(:one).skills, skills(:one)
  end

  test "has many user_skills" do
    assert_includes users(:one).user_skills, user_skills(:one)
  end

  test "has many messages" do
    assert_includes users(:one).messages, messages(:one)
  end

  test "has one user_skill_vector" do
    assert_respond_to users(:one), :user_skill_vector
  end

  test "moderator? sadece rol moderator ise true doner" do
    user = User.new(role: "moderator")
    assert user.moderator?
    assert_not user.admin?

    assert_not User.new(role: "member").moderator?
    assert_not User.new(role: "admin").moderator?
  end

  test "staff? admin veya moderator icin true, member icin false" do
    assert User.new(role: "admin").staff?
    assert User.new(role: "moderator").staff?
    assert_not User.new(role: "member").staff?
  end

  test "encrypts github_token" do
    user = users(:one)
    user.update!(github_token: "secret-token")
    assert_equal "secret-token", user.reload.github_token

    raw = ActiveRecord::Base.connection.select_value("SELECT github_token FROM users WHERE id = #{user.id}")
    refute_equal "secret-token", raw
  end

  test "gecerli bir gorsel banner_image olarak eklenebilir" do
    user = users(:one)
    user.banner_image.attach(io: StringIO.new("fake-image"), filename: "banner.png", content_type: "image/png")

    assert user.valid?
    assert user.banner_image.attached?
  end

  test "gorsel olmayan bir dosya banner_image olarak reddedilir" do
    user = users(:one)
    user.banner_image.attach(io: StringIO.new("not-an-image"), filename: "banner.txt", content_type: "text/plain")

    assert_not user.valid?
    assert_includes user.errors[:banner_image], "geçerli bir görsel olmalı (PNG, JPEG veya WEBP)"
  end

  test "protected_from_moderation admin rolunun degistirilmesini engeller" do
    user = User.create!(name: "Kurucu", provider: "github", uid: "prot-model-1", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)

    user.role = "member"

    assert_not user.valid?
    assert_includes user.errors[:role], "Bu hesabın admin yetkisi kaldırılamaz."
  end

  test "protected_from_moderation admin olmayan bir kullanicida rol degisimini engellemez" do
    user = User.create!(name: "Normal", provider: "github", uid: "prot-model-2", role: "member", terms_accepted_at: Time.current)

    user.role = "moderator"

    assert user.valid?
  end

  # --- Presence: canli cevrimici listesi yayini ---

  test "online_viewers_excluding yalnizca cevrimici olan digerlerini doner" do
    online_a = User.create!(name: "Online A", provider: "github", uid: "vex-on-a", terms_accepted_at: Time.current, is_online: true)
    online_b = User.create!(name: "Online B", provider: "github", uid: "vex-on-b", terms_accepted_at: Time.current, is_online: true)
    User.create!(name: "Offline C", provider: "github", uid: "vex-off-c", terms_accepted_at: Time.current, is_online: false)

    viewers = User.online_viewers_excluding(online_a)

    assert_includes viewers, online_b
    assert_not_includes viewers, online_a, "degisen kullanicinin kendisi haric tutulmali"
    assert viewers.all?(&:is_online?), "yalnizca cevrimici kullanicilar donmeli"
  end

  test "broadcast_online_users_change her cevrimici izleyicinin per-user stream'ine yayin yapar" do
    online_a = User.create!(name: "Bcast A", provider: "github", uid: "bcast-a", terms_accepted_at: Time.current, is_online: true)
    online_b = User.create!(name: "Bcast B", provider: "github", uid: "bcast-b", terms_accepted_at: Time.current, is_online: true)

    assert_broadcasts("online_users_for_#{online_b.id}", 1) do
      User.broadcast_online_users_change(online_a)
    end
  end

  test "cok buyuk banner_image reddedilir" do
    user = users(:one)
    oversized = "a" * (User::BANNER_IMAGE_MAX_SIZE + 1)
    user.banner_image.attach(io: StringIO.new(oversized), filename: "buyuk.png", content_type: "image/png")

    assert_not user.valid?
    assert_includes user.errors[:banner_image], "5MB'dan büyük olamaz"
  end
end
