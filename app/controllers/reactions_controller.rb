# One ❤️ per signed-in reader on a news post — a binary toggle, same shape as
# LessonCompletion/LessonBookmark. The count rides a counter_cache so the
# Turbo Stream re-render skips a COUNT(*).
class ReactionsController < ApplicationController
  before_action :set_reactable

  def create
    Current.user.reactions.create_or_find_by!(reactable: @reactable)
    respond
  end

  def destroy
    Current.user.reactions.destroy_by(reactable: @reactable)
    respond
  end

  private
    def set_reactable
      @reactable = Post.published.find_by!(slug: params[:post_slug])
    end

    def respond
      @reactable.reload # refresh reactions_count before re-rendering the button
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to post_path(@reactable) }
      end
    end
end
