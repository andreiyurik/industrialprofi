module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :signed_in?
  end

  class_methods do
    # Public pages: skip the gate but still restore Current.user from the
    # cookie, so progress and the header render for signed-in visitors.
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :restore_authentication, **options
    end

    def require_unauthenticated_access(**options)
      allow_unauthenticated_access(**options)
      before_action :redirect_signed_in_user_to_dashboard, **options
    end
  end

  private
    def signed_in?
      Current.user.present?
    end

    def require_authentication
      restore_authentication || request_authentication
    end

    def restore_authentication
      if session = find_session_by_cookie
        resume_session session
      end
    end

    def find_session_by_cookie
      if token = cookies.signed[:session_token]
        Session.find_by(token: token)
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url if request.get? || request.head?
      redirect_to new_session_path, alert: t("auth.sign_in_required")
    end

    def redirect_signed_in_user_to_dashboard
      redirect_to dashboard_path if signed_in?
    end

    def start_new_session_for(user)
      user.sessions.start!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        authenticated_as session
      end
    end

    def resume_session(session)
      session.resume user_agent: request.user_agent, ip_address: request.remote_ip
      authenticated_as session
    end

    def authenticated_as(session)
      Current.session = session
      cookies.signed.permanent[:session_token] = { value: session.token, httponly: true, same_site: :lax }
    end

    def terminate_current_session
      Current.session&.destroy!
      Current.session = nil
      reset_session
      cookies.delete(:session_token)
    end

    def post_authenticating_url
      session.delete(:return_to_after_authenticating) || dashboard_path
    end
end
