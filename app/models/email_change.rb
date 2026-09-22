# Mirrors Signup's verification-code flow, kept in the encrypted session.
class EmailChange
  include SessionVerificationCode

  private
    def session_key = :email_change
end
