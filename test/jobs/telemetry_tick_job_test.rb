require "test_helper"
require "turbo/broadcastable/test_helper"

class TelemetryTickJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  test "htop_data anlik solid_queue durumlarini ve yaklasik cevrimici sayisini dondurur" do
    User.create!(name: "Cevrimici", provider: "github", uid: "htop-online-1", role: "member", is_online: true, terms_accepted_at: Time.current)
    User.create!(name: "Cevrimdisi", provider: "github", uid: "htop-offline-1", role: "member", is_online: false, terms_accepted_at: Time.current)

    data = TelemetryTickJob.htop_data

    assert_equal %i[ready scheduled claimed failed].sort, data[:solid_queue_jobs_by_status].keys.sort
    assert data[:solid_queue_jobs_by_status].values.all? { |v| v.is_a?(Integer) }
    assert_operator data[:online_users], :>=, 1
    assert_kind_of Integer, data[:match_queue_depth]
  end

  test "broadcast htop bolumunu (SYSTEM_MONITOR) icerir" do
    streams = capture_turbo_stream_broadcasts "telemetry_dashboard" do
      TelemetryTickJob.perform_now
    end

    html = streams.map(&:to_html).join
    assert_match "SYSTEM_MONITOR", html
    assert_match "EŞLEŞTİRME KUYRUĞU", html
  end
end
