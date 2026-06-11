class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "IndustrialProfi <no-reply@industrialprofi.com>")
  layout "mailer"
end
