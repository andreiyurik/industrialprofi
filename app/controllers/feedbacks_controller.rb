class FeedbacksController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to new_feedback_path, alert: t("auth.rate_limited") }

  def new
    @feedback = Feedback.new(page_url: params[:from].presence)
  end

  def create
    @feedback = Current.user.feedbacks.new(feedback_params)

    if @feedback.save
      FeedbackMailer.new_message(@feedback).deliver_later
      redirect_to dashboard_path, notice: t("feedbacks.sent", email: Current.user.email_address)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def feedback_params
      params.expect(feedback: [ :body, :page_url ])
    end
end
