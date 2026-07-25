# Readers proposing a source (link) for a lesson — the community half of the
# "documents & resources" block. Mirrors LessonSuggestionsController: an account
# is required (real identity = trustworthy attribution + the trust ladder), and
# the same velocity + standing-backlog caps keep it spam-resistant.
class ResourceSuggestionsController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to lesson_path(params[:lesson_slug]), alert: t("auth.rate_limited") }

  MAX_PENDING_PER_USER = 20

  before_action :set_lesson
  before_action :ensure_pending_within_cap, only: :create

  def new
    @suggestion = @lesson.resource_suggestions.new
  end

  def create
    @suggestion = @lesson.resource_suggestions.new(suggestion_params)
    @suggestion.user = Current.user
    @suggestion.author_name = Current.user.name

    if @suggestion.save
      redirect_to lesson_path(@lesson), notice: t("resource_suggestions.submitted")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_lesson
    @lesson = Lesson.find_by!(slug: params[:lesson_slug])
  end

  def ensure_pending_within_cap
    return if Current.user.can_edit_content?
    return if Current.user.resource_suggestions.pending.count < MAX_PENDING_PER_USER

    redirect_to lesson_path(@lesson), alert: t("flash.too_many_pending")
  end

  def suggestion_params
    params.require(:resource_suggestion).permit(:url, :title, :kind, :note)
  end
end
