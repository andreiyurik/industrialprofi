class EmailChange
  ALPHABET = Signup::ALPHABET
  CODE_LENGTH = Signup::CODE_LENGTH
  CODE_TTL = 15.minutes

  def initialize(session)
    @session = session
  end

  def start!(email_address)
    code = Array.new(CODE_LENGTH) { ALPHABET[SecureRandom.random_number(ALPHABET.size)] }.join
    @session[:email_change] = {
      "email_address" => email_address,
      "code_digest"   => digest(code),
      "expires_at"    => CODE_TTL.from_now.to_i,
      "verified"      => false
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
      @session[:email_change] = state.merge("verified" => true)
      true
    else
      false
    end
  end

  def expired?
    state.nil? || Time.current.to_i > state["expires_at"].to_i
  end

  def clear!
    @session.delete(:email_change)
  end

  private
    def state = @session[:email_change]

    def digest(code)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, code)
    end
end
