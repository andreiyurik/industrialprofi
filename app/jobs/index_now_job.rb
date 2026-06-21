require "net/http"

# Pushes changed URLs to IndexNow — one endpoint that fans out to Yandex and Bing
# — so freshly published professions/courses/lessons get indexed in hours, not
# weeks. Enqueued by IndexNowNotifiable on content changes. Gem-free, fire-and-
# forget: a failed ping is logged, never fatal (search indexing must not take a
# request or a deploy down with it).
class IndexNowJob < ApplicationJob
  queue_as :default

  ENDPOINT = URI("https://api.indexnow.org/indexnow")

  def perform(urls)
    key = Rails.application.config.x.site.indexnow_key
    return if key.blank?

    urls = Array(urls).compact_blank
    return if urls.empty?

    submit(self.class.payload(urls, key))
  rescue => e
    Rails.logger.warn("IndexNow ping failed: #{e.class}: #{e.message}")
  end

  # Pure, testable: the JSON body IndexNow expects.
  def self.payload(urls, key)
    site = Rails.application.config.x.site
    {
      host: URI(site.url).host,
      key: key,
      keyLocation: "#{site.url}/#{key}.txt",
      urlList: Array(urls)
    }
  end

  private
    def submit(payload)
      http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Post.new(ENDPOINT.path, "Content-Type" => "application/json; charset=utf-8")
      request.body = payload.to_json
      http.request(request)
    end
end
