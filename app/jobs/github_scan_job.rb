class GithubScanJob < ApplicationJob
  queue_as :github

  limits_concurrency to: 1, key: ->(user_id) { user_id }, duration: 10.minutes

  RATE_LIMIT_SAFETY_MARGIN = 20

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.nil? || user.github_token.blank? || user.github_username.blank?

    client = Octokit::Client.new(access_token: user.github_token)
    client.auto_paginate = true

    headers = user.github_repos_etag.present? ? { "If-None-Match" => user.github_repos_etag } : {}

    begin
      repos = client.repos(user.github_username, { type: "owner", sort: "updated", headers: headers })
    rescue Octokit::TooManyRequests, Octokit::AbuseDetected
      reschedule(user_id, client)
      return
    end

    if client.last_response&.status == 304
      Rails.logger.info "[GithubScanJob] Kullanıcı ##{user.id}: repo listesi değişmemiş, tarama atlandı."
      return
    end

    user.update(github_repos_etag: client.last_response&.headers&.[](:etag))

    owned_repos = repos.reject { |repo| repo.fork }

    if client.rate_limit.remaining < owned_repos.size + RATE_LIMIT_SAFETY_MARGIN
      Rails.logger.warn "[GithubScanJob] Kullanıcı ##{user.id}: rate limit yetersiz (#{client.rate_limit.remaining} kaldı), erteleniyor."
      reschedule(user_id, client)
      return
    end

    # Repo listesi kaydi, dil hesaplamasindan BAGIMSIZ: bir kullanicinin repo'su
    # olmasi icin dil tespit edilmis olmasi sart degil. Bu yuzden dil hesabinin
    # (ve total_bytes.zero? erken donusunun) ONUNDE, tek bir toplu upsert ile
    # yaziyoruz (N+1 yok, bkz. MatchFinder#bulk_skill_weights ayni disiplin).
    persist_repositories(user, owned_repos)

    language_bytes = Hash.new(0)
    owned_repos.each do |repo|
      begin
        client.languages(repo.full_name).each { |language, bytes| language_bytes[language.to_s] += bytes }
      rescue Octokit::NotFound
        next
      end
    end

    total_bytes = language_bytes.values.sum
    return if total_bytes.zero?

    ActiveRecord::Base.transaction do
      language_bytes.each do |language_name, bytes|
        skill = SkillResolver.call(language_name, category: "language")
        user_skill = user.user_skills.find_or_initialize_by(skill: skill, source: "github")
        user_skill.direction ||= "teaching"

        user_skill.weight = (bytes.to_f / total_bytes).round(4)
        user_skill.save!
      end
    end

    user.update(skills_last_scanned_at: Time.current)
    Rails.logger.info "[GithubScanJob] Kullanıcı ##{user.id}: #{language_bytes.size} dil tespit edildi."



    GenerateUserEmbeddingJob.perform_later(user.id)
  end

  private



  def persist_repositories(user, owned_repos)
    return if owned_repos.empty?

    now = Time.current
    rows = owned_repos.map do |repo|
      {
        user_id: user.id,
        name: repo.name,
        full_name: repo.full_name,
        description: repo.description,
        primary_language: repo.language,
        stargazers_count: repo.stargazers_count || 0,
        html_url: repo.html_url,
        repo_updated_at: repo.updated_at,
        created_at: now,
        updated_at: now
      }
    end

    GithubRepository.upsert_all(rows, unique_by: [ :user_id, :full_name ])
  end


  def reschedule(user_id, client)
    retry_after = begin
      client.rate_limit.resets_in
    rescue StandardError
      60
    end
    self.class.set(wait: retry_after.seconds).perform_later(user_id)
  end
end
