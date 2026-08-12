require "net/smtp"

# Delivery retries on a flaky SMTP connection. Without it one blown handshake
# discards the letter for good — which is how the admin alert about a locked
# database went missing twice, leaving only a dead row in the failed queue.
# Permanent refusals (a bad address, a rejected message) still fail at once.
class MailDeliveryJob < ActionMailer::MailDeliveryJob
  retry_on Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Net::SMTPServerBusy,
           wait: :polynomially_longer, attempts: 5
end
