class ErrorMailer < ApplicationMailer
  def alert(error_class:, message:, backtrace:, severity:, source:, context:)
    @error_class = error_class
    @message = message
    @backtrace = backtrace
    @severity = severity
    @source = source
    @context = context

    recipients = alert_recipients
    return if recipients.empty?

    mail to: recipients,
         subject: "[#{t('site.name')}] #{severity}: #{error_class}: #{message.truncate(120)}"
  end

  private
    # ERROR_ALERTS_TO overrides (comma-separated); default is every administrator.
    def alert_recipients
      ENV["ERROR_ALERTS_TO"].presence&.split(",")&.map(&:strip) ||
        User.administrator.pluck(:email_address)
    end
end
