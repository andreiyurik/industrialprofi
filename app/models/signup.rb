# Step-by-step signup state (Fizzy-style), kept in the encrypted session —
# no table: nothing exists in the database until the final step creates the
# User, and abandoned signups evaporate with the session.
class Signup
  # Unambiguous alphabet: no I/L/O/S/0/1/5 lookalikes.
  ALPHABET = %w[A B C D E F G H J K M N P Q R T U V W X Y Z 2 3 4 6 7 8 9].freeze
  CODE_LENGTH = 6
  CODE_TTL = 15.minutes

  def initialize(session)
    @session = session
  end

  # Starts (or restarts) a signup: stores the email + code digest, returns the
  # plain code exactly once — for the mailer.
  def start!(email_address)
    code = Array.new(CODE_LENGTH) { ALPHABET[SecureRandom.random_number(ALPHABET.size)] }.join
    @session[:signup] = {
      "email_address" => email_address,
      "code_digest" => digest(code),
      "expires_at" => CODE_TTL.from_now.to_i,
      "verified" => false
    }
    code
  end

  def pending?
    state.present?
  end

  def verified?
    state.present? && state["verified"] == true
  end

  def email_address
    state&.fetch("email_address", nil)
  end

  def verify(code)
    return false if expired? || code.blank?

    if ActiveSupport::SecurityUtils.secure_compare(digest(code.strip.upcase), state["code_digest"].to_s)
      @session[:signup] = state.merge("verified" => true)
      true
    else
      false
    end
  end

  def expired?
    state.nil? || Time.current.to_i > state["expires_at"].to_i
  end

  def clear!
    @session.delete(:signup)
  end

  private
    def state
      @session[:signup]
    end

    def digest(code)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, code)
    end
end
