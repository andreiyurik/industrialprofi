# Shared plumbing for the three signup steps (email → code → profile).
module SignupFlow
  extend ActiveSupport::Concern

  included do
    require_unauthenticated_access
    helper_method :signup
  end

  private
    def signup
      @signup ||= Signup.new(session)
    end
end
