# Signup state kept in the encrypted session, not a table — nothing exists until
# the final step creates the User; abandoned signups evaporate with the session.
class Signup
  include SessionVerificationCode

  def verified?
    state.present? && state["verified"] == true
  end

  private
    def session_key = :signup
end
