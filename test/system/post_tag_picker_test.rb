require "application_system_test_case"

# Faz 31 — Post olusturma etiket secicisi (checkbox izgarasi yerine <datalist>
# tabanli, chip'li tag-picker) uctan uca dogrulamasi.
#
# Amac: kullanici yeni tag-picker UI'sinde bir yetenek adi yazip Enter'a
# bastiginda kaldirilabilir bir chip belirir ve arkada gizli bir skill_ids[]
# input'u olusur; form gonderilince post GERCEKTEN o skill ile etiketlenir.
# PostsController#create degistirilmedi — yalnizca on yuz secim UX'i degisti.
class PostTagPickerTest < ApplicationSystemTestCase
  MOCK_UID = "tag-picker-test-user"

  def setup
    OmniAuth.config.test_mode = true

    @user = User.create!(
      name: "Tag Picker Tester",
      provider: "github",
      uid: MOCK_UID,
      terms_accepted_at: Time.current
    )

    # Fixtures'ta "React" skill'i mevcut; kararliligi garanti etmek icin garantiye al.
    @skill = Skill.find_or_create_by!(name: "React") { |s| s.category = "frontend_framework" }

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

    # NOT: User modelinde `has_many :posts` bilerek tanimli degil (Post yalnizca
    # `belongs_to :user`). Bu yuzden temizligi iliski uzerinden degil, dogrudan
    # Post.where(user:) sorgusuyla yapiyoruz.
    Post.where(user: @user).destroy_all if @user
    @user&.destroy
  end

  test "tag-picker ile yetenek yazip chip eklenir ve post o skill ile olusturulur" do
    visit "/auth/github/callback"
    visit posts_path

    assert_selector "#post-compose"

    # Zorunlu icerik alanini doldur.
    within "#post-compose" do
      fill_in "content", with: "TAG_PICKER_TEST_POSTU"

      # Tag-picker input'una tam skill adini yaz + Enter → chip belirmeli.
      picker = find("input[data-tag-picker-target='input']")
      picker.set(@skill.name)
      picker.send_keys(:enter)

      # Chip + gizli skill_ids[] input'u olustu mu?
      within "[data-tag-picker-target='chips']" do
        assert_text @skill.name
        assert_selector "input[type='hidden'][name='skill_ids[]'][value='#{@skill.id}']", visible: :all
      end

      click_on "Yayınla"
    end

    # Post olustu ve dogru skill ile etiketlendi mi?
    assert_selector "#posts-list", text: "TAG_PICKER_TEST_POSTU"
    post = Post.where(user: @user).order(created_at: :desc).first
    assert_not_nil post
    assert_includes post.skills.map(&:name), @skill.name
  end
end
