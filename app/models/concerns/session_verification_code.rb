# Shared skeleton for a short-lived, session-backed verification code
# (signup email confirmation, account email-change confirmation): generate a
# human-typeable code, store its digest + expiry in the session, verify it,
# expire it. No table — nothing exists in the database until the flow
# completes, and an abandoned flow evaporates with the session.
module SessionVerificationCode
  extend ActiveSupport::Concern

  included do
    # Unambiguous alphabet: no I/L/O/S/0/1/5 lookalikes.
    const_set(:ALPHABET, %w[A B C D E F G H J K M N P Q R T U V W X Y Z 2 3 4 6 7 8 9].freeze)
    const_set(:CODE_LENGTH, 6)
    const_set(:CODE_TTL, 15.minutes)
  end

  def initialize(session)
    @session = session
  end

  # Starts (or restarts) the flow: stores the email + code digest, returns the
  # plain code exactly once — for the mailer.
  def start!(email_address)
    alphabet = self.class::ALPHABET
    code = Array.new(self.class::CODE_LENGTH) { alphabet[SecureRandom.random_number(alphabet.size)] }.join
    @session[session_key] = {
      "email_address" => email_address,
      "code_digest" => digest(code),
      "expires_at" => self.class::CODE_TTL.from_now.to_i,
      "verified" => false
    }
    code
  end

  def pending?
    state.present?
  end

  def email_address
    state&.fetch("email_address", nil)
  end

  def verify(code)
    return false if expired? || code.blank?

    if ActiveSupport::SecurityUtils.secure_compare(digest(code.strip.upcase), state["code_digest"].to_s)
      @session[session_key] = state.merge("verified" => true)
      true
    else
      false
    end
  end

  def expired?
    state.nil? || Time.current.to_i > state["expires_at"].to_i
  end

  def clear!
    @session.delete(session_key)
  end

  private
    def state
      @session[session_key]
    end

    def digest(code)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, code)
    end
end
