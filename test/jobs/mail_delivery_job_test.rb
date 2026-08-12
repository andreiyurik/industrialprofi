require "test_helper"

class MailDeliveryJobTest < ActiveSupport::TestCase
  test "every mailer delivers through the retrying job" do
    assert_equal MailDeliveryJob, ApplicationMailer.delivery_job
    assert_equal MailDeliveryJob, ErrorMailer.delivery_job
  end

  test "a timed-out SMTP connection retries instead of failing outright" do
    handlers = MailDeliveryJob.rescue_handlers.map(&:first)

    # Handlers are consulted in reverse registration order, so ours must come
    # after the StandardError one ActionMailer installs — otherwise a blown
    # handshake is reported and discarded instead of retried.
    assert_operator handlers.index("Net::OpenTimeout"), :>, handlers.index("StandardError")
  end
end
