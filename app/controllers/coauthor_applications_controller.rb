# The expert-entry gate (loop #1): a structured "стать соавтором" application.
# Requires sign-in — a co-author needs an account anyway, and it filters for
# seriousness. The fields are folded into a tagged Feedback (no separate model
# until real volume warrants tracking application status); the founder reads it
# in /admin/feedbacks, replies, and grants the editor role + editorship by hand.
class CoauthorApplicationsController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to new_coauthor_application_path, alert: t("auth.rate_limited") }

  # Three fields keep first contact low-friction; the rest (portfolio, specific
  # credentials) come up in the reply. All three are required — each is essential
  # to judge an application.
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

    feedback = Current.user.feedbacks.create!(body: compose_message, page_url: new_coauthor_application_path)
    FeedbackMailer.new_message(feedback).deliver_later
    redirect_to dashboard_path, notice: t("coauthor_applications.sent", email: Current.user.email_address)
  end

  private
    def application_params
      params.expect(coauthor_application: FIELDS)
    end

    # Fold the structured fields into a readable Feedback body. The header line
    # makes co-author applications recognizable among ordinary messages.
    def compose_message
      lines = [ t("coauthor_applications.message.header") ]
      FIELDS.each do |field|
        value = @application[field]
        lines << "#{t("coauthor_applications.message.#{field}")}: #{value}" if value.present?
      end
      lines.join("\n\n")
    end
end
