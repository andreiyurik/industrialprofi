class PathsController < ApplicationController
  def index
    @paths = Path.published.ordered
  end

  def show
    @path = Path.published.find_by!(slug: params[:slug])
    @lessons = @path.lessons.to_a
    @lessons_by_stage = @lessons.group_by(&:stage)
  end
end
