class FeedbacksController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to new_feedback_path, alert: t("auth.rate_limited") }

  def new
    @feedback = Feedback.new(page_url: params[:from].presence)
    # Arriving from the catalog's "предложить профессию" tile: tailor the page and
    # seed a marker so profession ideas stand out in the founder's inbox. Still a
    # plain Feedback — no separate model for a low-volume, free-text channel.
    if params[:about] == "profession"
      @feedback.body = t("feedbacks.profession_prefill")
      @title = t("feedbacks.profession_title")
      @intro = t("feedbacks.profession_intro")
    end
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
