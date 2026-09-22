# One ❤️ per reader, same toggle shape as LessonCompletion/LessonBookmark; counter_cache
# lets the Turbo Stream re-render skip a COUNT(*).
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
