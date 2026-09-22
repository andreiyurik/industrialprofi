require "net/smtp"

# Retries transient SMTP failures — a blown handshake would otherwise silently drop the
# letter for good. Permanent refusals (bad address, rejected message) still fail at once.
class MailDeliveryJob < ActionMailer::MailDeliveryJob
  retry_on Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Net::SMTPServerBusy,
           wait: :polynomially_longer, attempts: 5
end
