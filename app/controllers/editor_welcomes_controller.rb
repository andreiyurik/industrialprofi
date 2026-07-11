# Dismisses the founder's one-shot letter to a newly promoted editor. A real
# POST (not a JS close): the letter must stay until acknowledged, and must
# never be consumed by a prefetch — so the flag flips only here.
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
