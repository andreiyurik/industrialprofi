# Pings IndexNow (Yandex + Bing) when a publicly-visible record is created or
# meaningfully changed, so new professions/courses/lessons get crawled fast.
# Including models define two methods:
#   indexnow_url          → the public URL, or nil if the record isn't public
#   indexnow_should_ping? → true only on a change worth re-indexing
# The whole thing is a no-op unless an INDEXNOW_KEY is configured, so dev and
# test never reach out to the network.
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
