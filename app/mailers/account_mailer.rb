class AccountMailer < ApplicationMailer
  def email_change_code(email_address, code)
    @code = code
    mail to: email_address, subject: t("account_mailer.email_change_code.subject", code: code)
  end
end
