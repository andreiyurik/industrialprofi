# Folded into a tagged Feedback — no separate model until volume warrants tracking status;
# founder reads it in /admin/feedbacks, replies, and grants the editor role by hand.
class CoauthorApplicationsController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to new_coauthor_application_path, alert: t("auth.rate_limited") }

  # Kept to three fields for low-friction first contact; portfolio/credentials come up in the reply.
  FIELDS = %i[profession background motivation].freeze

  def new
    @application = {}
  end

  def create
    @application = application_params.to_h.symbolize_keys

    if FIELDS.any? { |field| @application[field].blank? }
      flash.now[:alert] = t("coauthor_applications.incomplete")
      return render :new, status: :unprocessable_entity
    end

    body = Feedback.compose_message(:coauthor_applications, fields: FIELDS, values: @application)
    feedback = Current.user.feedbacks.create!(body: body, page_url: Feedback::COAUTHOR_APPLICATION_PATH)
    FeedbackMailer.new_message(feedback).deliver_later
    redirect_to dashboard_path, notice: t("coauthor_applications.sent", email: Current.user.email_address)
  end

  private
    def application_params
      params.expect(coauthor_application: FIELDS)
    end
end
