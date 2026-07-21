require "test_helper"

class ProfileWidgetTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Profil Widget Sahibi", provider: "github", uid: "pw-model-1", terms_accepted_at: Time.current)
  end

  test "gecerli widget kaydedilir" do
    widget = ProfileWidget.new(user: @user, widget_type: "identity")
    assert widget.valid?
    assert widget.save
  end

  test "widget_type WIDGET_TYPES icinde olmali" do
    widget = ProfileWidget.new(user: @user, widget_type: "bilinmeyen_tip")
    assert_not widget.valid?
    assert_includes widget.errors[:widget_type], "is not included in the list"
  end

  test "widget_type bos olamaz" do
    widget = ProfileWidget.new(user: @user, widget_type: nil)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :widget_type
  end

  test "ayni kullanicida ayni widget_type tekrar edilemez" do
    ProfileWidget.create!(user: @user, widget_type: "identity")
    dup = ProfileWidget.new(user: @user, widget_type: "identity")
    assert_not dup.valid?
    assert_includes dup.errors[:widget_type], "has already been taken"
  end

  test "farkli kullanicilar ayni widget_type'a sahip olabilir" do
    other = User.create!(name: "Diger Profil", provider: "github", uid: "pw-model-2", terms_accepted_at: Time.current)
    ProfileWidget.create!(user: @user, widget_type: "identity")
    widget = ProfileWidget.new(user: other, widget_type: "identity")
    assert widget.valid?
  end

  test "width sifir veya negatif olamaz" do
    widget = ProfileWidget.new(user: @user, widget_type: "identity", width: 0)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :width
  end

  test "height sifir veya negatif olamaz" do
    widget = ProfileWidget.new(user: @user, widget_type: "identity", height: -1)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :height
  end

  test "position_x negatif olamaz" do
    widget = ProfileWidget.new(user: @user, widget_type: "identity", position_x: -1)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :position_x
  end

  test "reposts gecerli bir widget_type'tir" do
    widget = ProfileWidget.new(user: @user, widget_type: "reposts")
    assert widget.valid?
  end

  test "kaldirilan match_analysis artik gecerli bir widget_type degildir" do
    widget = ProfileWidget.new(user: @user, widget_type: "match_analysis")
    assert_not widget.valid?
    assert_includes widget.errors[:widget_type], "is not included in the list"
  end

  test "width 12'den buyuk olamaz" do
    widget = ProfileWidget.new(user: @user, widget_type: "identity", position_x: 0, width: 13)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :width
  end

  test "position_x + width 12 kolonluk izgarayi asamaz (cakisma sertlestirmesi)" do
    overflow = ProfileWidget.new(user: @user, widget_type: "identity", position_x: 7, width: 6)
    assert_not overflow.valid?
    assert_includes overflow.errors.attribute_names, :width

    edge = ProfileWidget.new(user: @user, widget_type: "identity", position_x: 4, width: 8)
    assert edge.valid?
  end

  test "font_scale araligi 0.5 ile 2.0 arasinda olmali" do
    too_small = ProfileWidget.new(user: @user, widget_type: "identity", font_scale: 0.3)
    assert_not too_small.valid?
    assert_includes too_small.errors.attribute_names, :font_scale

    too_large = ProfileWidget.new(user: @user, widget_type: "identity", font_scale: 2.5)
    assert_not too_large.valid?

    ok = ProfileWidget.new(user: @user, widget_type: "identity", font_scale: 1.5)
    assert ok.valid?
  end

  test "seed_defaults_for tam olarak 5 widget olusturur" do
    widgets = ProfileWidget.seed_defaults_for(@user)
    assert_equal 5, widgets.length
    assert_equal 5, ProfileWidget.where(user: @user).count
  end

  test "seed_defaults_for tum widget'lari gorunur birakir" do
    ProfileWidget.seed_defaults_for(@user)
    assert_equal 5, ProfileWidget.where(user: @user, visible: true).count
    assert_equal 0, ProfileWidget.where(user: @user, visible: false).count
  end

  test "seed_defaults_for tum WIDGET_TYPES'i tekrarsiz olusturur" do
    ProfileWidget.seed_defaults_for(@user)
    types = ProfileWidget.where(user: @user).pluck(:widget_type)
    assert_equal ProfileWidget::WIDGET_TYPES.sort, types.sort
    assert_equal types.uniq.length, types.length
  end

  test "seed_defaults_for varsayilan yerlesim gecerli (tum widget'lar kaydedildi)" do
    widgets = ProfileWidget.seed_defaults_for(@user)
    assert widgets.all?(&:persisted?)
    assert widgets.all?(&:valid?)
  end

  test "seed_defaults_for none? ile korunursa idempotent" do
    ProfileWidget.seed_defaults_for(@user)
    assert_equal 5, ProfileWidget.where(user: @user).count

    ProfileWidget.seed_defaults_for(@user) if ProfileWidget.where(user: @user).none?
    assert_equal 5, ProfileWidget.where(user: @user).count
  end

  test "kullanici silinince profil widget'lari da silinir (FK cascade)" do
    ProfileWidget.seed_defaults_for(@user)
    assert_equal 5, ProfileWidget.where(user: @user).count

    @user.destroy
    assert_equal 0, ProfileWidget.where(user_id: @user.id).count
  end

  test "reset_defaults_for! ozellestirilmis yerlesimi varsayilana dondurur" do
    ProfileWidget.seed_defaults_for(@user)

    # Kullanici yerlesimi ozellestirsin: bir widget'i tasi, birini sil.
    identity = ProfileWidget.where(user: @user).find_by(widget_type: "identity")
    identity.update!(position_x: 2, position_y: 9, width: 3, height: 2, visible: false)
    ProfileWidget.where(user: @user).find_by(widget_type: "github_repos").destroy!

    ProfileWidget.reset_defaults_for!(@user)

    assert_equal 5, ProfileWidget.where(user: @user).count

    reset_layout = ProfileWidget.where(user: @user).order(:widget_type).map do |w|
      { widget_type: w.widget_type, position_x: w.position_x, position_y: w.position_y,
        width: w.width, height: w.height, visible: w.visible }
    end
    expected_layout = ProfileWidget::DEFAULT_LAYOUT.map(&:dup).sort_by { |a| a[:widget_type] }

    assert_equal expected_layout, reset_layout
  end

  test "reset_defaults_for! zaten ozellestirilmis kullanicida bile calisir (seed_defaults_for'un aksine hata vermez)" do
    ProfileWidget.seed_defaults_for(@user)
    assert_raises(ActiveRecord::RecordInvalid) { ProfileWidget.seed_defaults_for(@user) }

    assert_nothing_raised { ProfileWidget.reset_defaults_for!(@user) }
    assert_equal 5, ProfileWidget.where(user: @user).count
  end
end
