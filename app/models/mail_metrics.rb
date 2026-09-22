# Cheap "is mail flow alive?" signal — registration is gated on working SMTP, so
# a sudden zero matters. Per-day keys self-expire (no table, no disk growth).
# Every cache touch is rescue-guarded: counting must never break the delivery it counts.
class MailMetrics
  # A touch over the 7-day window we display, so old day-keys evict themselves.
  RETENTION = 8.days

  class << self
    # Non-atomic on purpose: at mail volumes a rare lost increment doesn't matter,
    # and it works the same on every cache store, including the test null-store.
    def record_delivery(on: Date.current)
      key = key_for(on)
      Rails.cache.write(key, sent_on(on) + 1, raw: true, expires_in: RETENTION)
    rescue StandardError
      nil
    end

    # One read_multi, so the dashboard pays a single cache lookup; nil if unavailable.
    def sent_last(days)
      keys = (0...days).map { |i| key_for(Date.current - i) }
      Rails.cache.read_multi(*keys, raw: true).values.sum { |value| value.to_i }
    rescue StandardError
      nil
    end

    private
      def sent_on(date) = Rails.cache.read(key_for(date), raw: true).to_i

      def key_for(date) = "mail_sent:#{date.iso8601}"
  end
end
