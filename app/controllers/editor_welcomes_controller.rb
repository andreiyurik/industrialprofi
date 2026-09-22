# Real POST, not a JS close: a GET prefetch must never consume this, so the flag flips only here.
class EditorWelcomesController < ApplicationController
  def destroy
    Current.user.update!(editor_welcomed_at: Time.current)
    if params[:open_queue]
      redirect_to admin_lesson_suggestions_path
    else
      redirect_back_or_to dashboard_path
    end
  end
end
