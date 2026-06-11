class DashboardController < ApplicationController
  def show
    @started_paths = Current.user.started_paths.includes(:lessons)
    @completed_ids_by_path = @started_paths.index_with { |path| Current.user.completed_lesson_ids_for(path) }
    @suggested_paths = Path.published.official.localized.ordered.where.not(id: @started_paths.map(&:id)).limit(3)
  end
end
