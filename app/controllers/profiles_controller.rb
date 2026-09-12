# A person's public page: identity, their map, what they improved (each claim
# links to a checkable revision), and — only if they chose so — what they are
# learning. Nothing here is self-assigned except the headline, labelled as such.
class ProfilesController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.with_profile.find_by!(handle: params[:handle])
    @map = Map.readable.find_by(user: @user)
    @curated_paths = @user.curated_paths.to_a
    @improved_lessons = @user.improved_lessons.to_a
    load_progress if @user.show_progress?
  end

  private
    def load_progress
      @started_paths = @user.started_paths.to_a
      @completed_counts = @user.lesson_completions.joins(:lesson).group("lessons.path_id").count
      @activity_since = 15.weeks.ago.to_date.beginning_of_week
      @activity = @user.activity_by_day(since: @activity_since)
    end
end
