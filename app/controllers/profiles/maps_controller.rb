# The shared link: someone's map, readable by anyone. Signed-in readers see
# their own ticks on its lessons and can take the map to their dashboard.
class Profiles::MapsController < ApplicationController
  allow_unauthenticated_access

  def show
    @author = User.with_profile.find_by!(handle: params[:profile_handle])
    @map = Map.readable.find_by(user: @author) or raise ActiveRecord::RecordNotFound
    @lessons_by_course = @map.lessons_by_course
    @extras = @map.extras_by_lesson
    @loose_links = @extras.delete(nil)&.links || []
    @completed_ids = Current.user&.completed_lesson_ids || Set.new
    @follow = Current.user&.map_follows&.find_by(map: @map)
  end
end
