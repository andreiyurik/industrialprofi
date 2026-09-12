# «Взять карту» / «Убрать»: keep (or drop) someone's map on my dashboard.
class Profiles::FollowsController < ApplicationController
  before_action :set_map

  def create
    if @map.user == Current.user
      redirect_to profile_map_path(@map), alert: t(".own")
    else
      Current.user.map_follows.find_or_create_by!(map: @map)
      redirect_to profile_map_path(@map), notice: t(".taken")
    end
  end

  def destroy
    Current.user.map_follows.destroy_by(map: @map)
    redirect_to profile_map_path(@map), notice: t(".dropped")
  end

  private
    def set_map
      author = User.with_profile.find_by!(handle: params[:profile_handle])
      @map = author.map or raise ActiveRecord::RecordNotFound
    end
end
