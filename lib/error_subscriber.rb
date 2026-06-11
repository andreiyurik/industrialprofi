# Hand-rolled error monitoring (no SaaS, no gems) — subscribes to the Rails
# error reporter, which receives every unhandled exception from web requests
# and Solid Queue jobs. Each new error emails the administrators; a Solid Cache
# throttle keeps a repeating error from becoming an inbox storm.
#
# Subscribed in production only — see config/initializers/error_reporting.rb.
class ErrorSubscriber
  THROTTLE_TTL = 30.minutes

  def report(error, handled:, severity:, context:, source: nil)
    return if handled
    return unless first_occurrence_recently?(error)

    # Exceptions don't serialize through Active Job — pass primitives.
    ErrorMailer.alert(
      error_class: error.class.name,
      message: error.message.to_s.truncate(1_000),
      backtrace: Array(error.backtrace).first(25),
      severity: severity.to_s,
      source: source.to_s,
      context: context.inspect.truncate(1_000)
    ).deliver_later
  rescue => e
    # Monitoring must never take the app down with it.
    Rails.logger.error("ErrorSubscriber failed: #{e.class}: #{e.message}")
  end

  private
    def first_occurrence_recently?(error)
      key = "error_alert:#{error.class.name}:#{error.message.to_s.first(100)}"
      Rails.cache.write(key, true, unless_exist: true, expires_in: THROTTLE_TTL)
    end
end
