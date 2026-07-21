module ApplicationHelper
  def safe_url(url)
    return nil if url.blank?
    url.match?(/\Ahttps?:\/\//) ? url : nil
  end
end
