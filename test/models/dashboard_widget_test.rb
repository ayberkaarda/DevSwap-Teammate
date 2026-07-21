require "test_helper"

class DashboardWidgetTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Widget Sahibi", provider: "github", uid: "dw-model-1", terms_accepted_at: Time.current)
  end

  test "gecerli widget kaydedilir" do
    widget = @user.dashboard_widgets.build(widget_type: "chatbox")
    assert widget.valid?
    assert widget.save
  end

  test "widget_type WIDGET_TYPES icinde olmali" do
    widget = @user.dashboard_widgets.build(widget_type: "bilinmeyen_tip")
    assert_not widget.valid?
    assert_includes widget.errors[:widget_type], "is not included in the list"
  end

  test "widget_type bos olamaz" do
    widget = @user.dashboard_widgets.build(widget_type: nil)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :widget_type
  end

  test "ayni kullanicida ayni widget_type tekrar edilemez" do
    @user.dashboard_widgets.create!(widget_type: "clock")
    dup = @user.dashboard_widgets.build(widget_type: "clock")
    assert_not dup.valid?
    assert_includes dup.errors[:widget_type], "has already been taken"
  end

  test "farkli kullanicilar ayni widget_type'a sahip olabilir" do
    other = User.create!(name: "Diger", provider: "github", uid: "dw-model-2", terms_accepted_at: Time.current)
    @user.dashboard_widgets.create!(widget_type: "clock")
    widget = other.dashboard_widgets.build(widget_type: "clock")
    assert widget.valid?
  end

  test "width sifir veya negatif olamaz" do
    widget = @user.dashboard_widgets.build(widget_type: "weather", width: 0)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :width
  end

  test "height sifir veya negatif olamaz" do
    widget = @user.dashboard_widgets.build(widget_type: "weather", height: -1)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :height
  end

  test "position_x negatif olamaz" do
    widget = @user.dashboard_widgets.build(widget_type: "weather", position_x: -1)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :position_x
  end

  test "width 12'den buyuk olamaz" do
    widget = @user.dashboard_widgets.build(widget_type: "weather", position_x: 0, width: 13)
    assert_not widget.valid?
    assert_includes widget.errors.attribute_names, :width
  end

  test "position_x + width 12 kolonluk izgarayi asamaz (cakisma sertlestirmesi)" do
    # x=7, w=6 => 13 > 12: ızgara sınırını aşar, reddedilmeli.
    overflow = @user.dashboard_widgets.build(widget_type: "weather", position_x: 7, width: 6)
    assert_not overflow.valid?
    assert_includes overflow.errors.attribute_names, :width

    # x=6, w=6 => 12: tam sınırda, gecerli.
    edge = @user.dashboard_widgets.build(widget_type: "weather", position_x: 6, width: 6)
    assert edge.valid?
  end

  test "font_scale araligi 0.5 ile 2.0 arasinda olmali" do
    too_small = @user.dashboard_widgets.build(widget_type: "weather", font_scale: 0.3)
    assert_not too_small.valid?
    assert_includes too_small.errors.attribute_names, :font_scale

    too_large = @user.dashboard_widgets.build(widget_type: "weather", font_scale: 2.5)
    assert_not too_large.valid?

    ok = @user.dashboard_widgets.build(widget_type: "weather", font_scale: 1.5)
    assert ok.valid?
  end

  test "seed_defaults_for tam olarak 11 widget olusturur" do
    widgets = DashboardWidget.seed_defaults_for(@user)
    assert_equal 11, widgets.length
    assert_equal 11, @user.dashboard_widgets.count
  end

  test "seed_defaults_for yalnizca cekirdek seti gorunur birakir (curated default)" do
    DashboardWidget.seed_defaults_for(@user)
    visible_types = @user.dashboard_widgets.where(visible: true).pluck(:widget_type).sort
    assert_equal %w[chatbox clock match_algorithm notifications quick_actions recent_posts].sort, visible_types
    # Geri kalanlar seed edilir ama gizli baslar (kayipsiz, "Gizli" listesinden acilir).
    assert_equal 5, @user.dashboard_widgets.where(visible: false).count
  end

  test "dev_feed artik gecerli bir widget turu degil (emekli edildi)" do
    assert_not_includes DashboardWidget::WIDGET_TYPES, "dev_feed"
    widget = @user.dashboard_widgets.build(widget_type: "dev_feed")
    assert_not widget.valid?
  end

  test "seed_defaults_for tum WIDGET_TYPES'i tekrarsiz olusturur" do
    DashboardWidget.seed_defaults_for(@user)
    types = @user.dashboard_widgets.pluck(:widget_type)
    assert_equal DashboardWidget::WIDGET_TYPES.sort, types.sort
    assert_equal types.uniq.length, types.length
  end

  test "seed_defaults_for varsayilan yerlesim gecerli (tum widget'lar kaydedildi)" do
    widgets = DashboardWidget.seed_defaults_for(@user)
    assert widgets.all?(&:persisted?)
    assert widgets.all?(&:valid?)
  end

  test "seed_defaults_for none? ile korunursa idempotent (ikinci cagri yeni kayit eklemez)" do
    DashboardWidget.seed_defaults_for(@user)
    assert_equal 11, @user.dashboard_widgets.count

    DashboardWidget.seed_defaults_for(@user) if @user.dashboard_widgets.reload.none?
    assert_equal 11, @user.dashboard_widgets.count
  end

  test "reset_defaults_for! ozellestirilmis yerlesimi varsayilana dondurur" do
    DashboardWidget.seed_defaults_for(@user)

    # Kullanici yerlesimi ozellestirsin: bir widget'i tasi, birini sil.
    chatbox = @user.dashboard_widgets.find_by(widget_type: "chatbox")
    chatbox.update!(position_x: 5, position_y: 9, width: 3, height: 2, visible: false)
    @user.dashboard_widgets.find_by(widget_type: "clock").destroy!

    DashboardWidget.reset_defaults_for!(@user)

    @user.reload
    assert_equal 11, @user.dashboard_widgets.count

    reset_layout = @user.dashboard_widgets.order(:widget_type).map do |w|
      { widget_type: w.widget_type, position_x: w.position_x, position_y: w.position_y,
        width: w.width, height: w.height, visible: w.visible }
    end
    expected_layout = DashboardWidget::DEFAULT_LAYOUT.map(&:dup).sort_by { |a| a[:widget_type] }

    assert_equal expected_layout, reset_layout
  end

  test "reset_defaults_for! zaten ozellestirilmis kullanicida bile calisir (seed_defaults_for'un aksine hata vermez)" do
    DashboardWidget.seed_defaults_for(@user)
    assert_raises(ActiveRecord::RecordInvalid) { DashboardWidget.seed_defaults_for(@user) }

    assert_nothing_raised { DashboardWidget.reset_defaults_for!(@user) }
    assert_equal 11, @user.dashboard_widgets.count
  end
end
