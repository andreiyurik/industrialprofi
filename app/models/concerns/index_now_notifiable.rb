# Pings IndexNow (Yandex + Bing) when a public record changes, so new content gets crawled fast.
# Including models define indexnow_url (nil if not public) and indexnow_should_ping?.
# No-op unless INDEXNOW_KEY is configured — dev/test never reach the network.
module IndexNowNotifiable
  extend ActiveSupport::Concern

  included do
    after_commit :notify_indexnow, on: [ :create, :update ]
  end

  private
    def notify_indexnow
      return if Rails.application.config.x.site.indexnow_key.blank?
      return unless indexnow_should_ping?

      url = indexnow_url
      IndexNowJob.perform_later([ url ]) if url.present?
    end

    def indexnow_site_url
      Rails.application.config.x.site.url
    end
end
