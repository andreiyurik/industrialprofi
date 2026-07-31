# Account email-change confirmation state, kept in the encrypted session —
# mirrors Signup's verification-code flow (see SessionVerificationCode).
class EmailChange
  include SessionVerificationCode

  private
    def session_key = :email_change
end
