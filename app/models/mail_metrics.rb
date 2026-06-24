# Counts outgoing mail into Solid Cache so the admin dashboard can show a cheap
# "is the mail flow alive?" signal — registration is hard-gated on a working
# SMTP, so a sudden zero is worth seeing. Per-day keys self-expire, so there's
# no table and no disk growth. Counting must never break the delivery it counts,
# so every cache touch is rescue-guarded (and a no-op on the test null-store).
class MailMetrics
  # A touch over the 7-day window we display, so old day-keys evict themselves.
  RETENTION = 8.days

  class << self
    # Bump today's counter. Read-modify-write is non-atomic on purpose: at mail
    # volumes a rare lost increment is irrelevant for a rough signal, and it
    # behaves identically on every cache store (incl. the test null-store).
    def record_delivery(on: Date.current)
      key = key_for(on)
      Rails.cache.write(key, sent_on(on) + 1, raw: true, expires_in: RETENTION)
    rescue StandardError
      nil
    end

    # Mail counted across the last `days` calendar days (today inclusive). One
    # read_multi, so the dashboard pays a single cache lookup. nil if unavailable.
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
