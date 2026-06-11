class SignupsMailer < ApplicationMailer
  def verification_code(email_address, code)
    @code = code
    mail to: email_address, subject: t("signups_mailer.verification_code.subject", code: code)
  end
end
