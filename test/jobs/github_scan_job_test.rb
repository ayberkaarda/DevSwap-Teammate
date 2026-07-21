require "test_helper"
require "ostruct"

class GithubScanJobTest < ActiveJob::TestCase
  # Octokit::Client'i canli API'ye gitmeden taklit eden basit fake'ler.
  # Projede mocha/webmock/vcr yok, bu yuzden Minitest'in Object#stub'i ile
  # Octokit::Client.new cagrisini fake bir client'a yonlendiriyoruz.
  class FakeResponse
    def initialize(status:, etag:)
      @status = status
      @etag = etag
    end

    attr_reader :status

    def headers
      { etag: @etag }
    end
  end

  class FakeRateLimit
    def remaining = 5000
    def resets_in = 60
  end

  class FakeClient
    attr_accessor :auto_paginate

    def initialize(repos:, languages: {})
      @repos = repos
      @languages = languages
    end

    def repos(_username, _opts = {})
      @repos
    end

    def last_response
      FakeResponse.new(status: 200, etag: "etag-abc")
    end

    def rate_limit
      FakeRateLimit.new
    end

    def languages(_full_name)
      @languages
    end
  end

  def build_repo(overrides = {})
    OpenStruct.new({
      fork: false,
      name: "devswap",
      full_name: "octocat/devswap",
      description: "Karsilikli skill takasi",
      language: "Ruby",
      stargazers_count: 42,
      html_url: "https://github.com/octocat/devswap",
      updated_at: Time.utc(2026, 1, 1, 12, 0, 0)
    }.merge(overrides))
  end

  def scan_user

    user = User.create!(name: "Repo Sahibi", provider: "github", uid: "gs-#{SecureRandom.hex(4)}", terms_accepted_at: Time.current)

    user = User.create!(name: "Repo Sahibi", provider: "github", uid: "gs-#{SecureRandom.hex(4)}")

    user.update!(github_username: "octocat", github_token: "test-token")
    user
  end

  # Octokit::Client.new'i gecici olarak fake bir client dondurecek sekilde
  # override eder; blok bitince singleton metodu kaldirip Class#new'i geri getirir.
  def with_fake_client(fake)
    Octokit::Client.define_singleton_method(:new) { |*, **| fake }
    yield
  ensure
    Octokit::Client.singleton_class.send(:remove_method, :new)
  end

  test "owned repo'lar GithubRepository tablosuna dogru alanlarla yazilir" do
    user = scan_user
    fake = FakeClient.new(repos: [ build_repo ], languages: { "Ruby" => 100 })

    with_fake_client(fake) do
      GithubScanJob.new.perform(user.id)
    end

    repo = GithubRepository.find_by(user_id: user.id, full_name: "octocat/devswap")
    assert repo.present?
    assert_equal "devswap", repo.name
    assert_equal "Karsilikli skill takasi", repo.description
    assert_equal "Ruby", repo.primary_language
    assert_equal 42, repo.stargazers_count
    assert_equal "https://github.com/octocat/devswap", repo.html_url
    assert_equal Time.utc(2026, 1, 1, 12, 0, 0), repo.repo_updated_at
  end

  test "fork repo'lar kaydedilmez" do
    user = scan_user
    fake = FakeClient.new(
      repos: [ build_repo, build_repo(fork: true, full_name: "octocat/forked", name: "forked") ],
      languages: { "Ruby" => 100 }
    )

    with_fake_client(fake) do
      GithubScanJob.new.perform(user.id)
    end

    assert_equal 1, GithubRepository.where(user_id: user.id).count
    assert_nil GithubRepository.find_by(user_id: user.id, full_name: "octocat/forked")
  end

  test "hicbir dil tespit edilemese bile repo listesi kaydedilir" do
    user = scan_user
    # languages bos -> total_bytes.zero? erken donus tetiklenir; yine de repo yazilmali.
    fake = FakeClient.new(repos: [ build_repo ], languages: {})

    with_fake_client(fake) do
      GithubScanJob.new.perform(user.id)
    end

    assert_equal 1, GithubRepository.where(user_id: user.id).count
    assert_equal 0, user.user_skills.count
  end

  test "tekrar taramada upsert ile duplicate olusmaz, ayni full_name guncellenir" do
    user = scan_user

    with_fake_client(FakeClient.new(repos: [ build_repo(stargazers_count: 42) ], languages: { "Ruby" => 100 })) do
      GithubScanJob.new.perform(user.id)
    end

    with_fake_client(FakeClient.new(repos: [ build_repo(stargazers_count: 99, description: "Guncellenmis") ], languages: { "Ruby" => 100 })) do
      GithubScanJob.new.perform(user.id)
    end

    repos = GithubRepository.where(user_id: user.id)
    assert_equal 1, repos.count
    repo = repos.first
    assert_equal 99, repo.stargazers_count
    assert_equal "Guncellenmis", repo.description
  end
end
