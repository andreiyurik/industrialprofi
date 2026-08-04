class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "IndustrialProfi <no-reply@industrialprofi.com>"),
          # The founder's real mailbox: replies to any letter land with a human.
          # Unset → the header is simply omitted.
          reply_to: ENV["MAIL_REPLY_TO"]
  layout "mailer"
  helper MailerHelper

  private
    # Letters render in the recipient's language: mailers that address a known
    # user assign @user before calling mail. URLs inside carry the same locale.
    def mail(...)
      I18n.with_locale(recipient_locale) { super }
    end

    def recipient_locale
      @user&.locale || I18n.locale
    end

    def default_url_options
      super.merge(locale: I18n.locale)
    end
end
