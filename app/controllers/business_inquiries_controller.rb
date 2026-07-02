# The B2B demand sensor (/business): training centers and employers tell us
# what they need before anything gets built — the founder decides from real
# inquiries, not guesses (docs/VISION.md → Business model). Public on purpose:
# a training-center director has no learner account. Folded into a tagged
# Feedback (coauthor-application pattern) — one inbox, no new model.
class BusinessInquiriesController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to business_path, alert: t("auth.rate_limited") }

  FIELDS = %i[organization contact message].freeze

  def new
    @inquiry = {}
  end

  def create
    # Honeypot: bots fill the hidden "company" field — pretend success, save nothing.
    if params[:company].present?
      return redirect_to business_path, notice: t("business_inquiries.sent")
    end

    @inquiry = inquiry_params.to_h.symbolize_keys

    if FIELDS.any? { |field| @inquiry[field].blank? }
      flash.now[:alert] = t("business_inquiries.incomplete")
      return render :new, status: :unprocessable_entity
    end

    feedback = Feedback.create!(user: Current.user, body: compose_message, page_url: business_path)
    FeedbackMailer.new_message(feedback).deliver_later
    redirect_to business_path, notice: t("business_inquiries.sent")
  end

  private
    def inquiry_params
      params.expect(business_inquiry: FIELDS)
    end

    # Fold the structured fields into a readable Feedback body. The header line
    # makes business inquiries recognizable among ordinary messages.
    def compose_message
      lines = [ t("business_inquiries.message.header") ]
      FIELDS.each do |field|
        lines << "#{t("business_inquiries.message.#{field}")}: #{@inquiry[field]}"
      end
      lines.join("\n\n")
    end
end
