# Step-by-step signup state (Fizzy-style), kept in the encrypted session —
# no table: nothing exists in the database until the final step creates the
# User, and abandoned signups evaporate with the session.
class Signup
  include SessionVerificationCode

  def verified?
    state.present? && state["verified"] == true
  end

  private
    def session_key = :signup
end
