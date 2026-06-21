class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "IndustrialProfi <no-reply@industrialprofi.com>"),
          # The founder's real mailbox: replies to any letter land with a human.
          # Unset → the header is simply omitted.
          reply_to: ENV["MAIL_REPLY_TO"]
  layout "mailer"
end
