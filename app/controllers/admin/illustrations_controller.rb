module Admin
  # The illustration backlog: every lesson image the author only briefed (a
  # "TODO-*.png" / "placeholder: …" stand-in) and nobody has drawn or photographed
  # yet. Read-only — it turns "open every lesson to find the gaps" into one queue,
  # grouped by profession, each row linking into the editor to fill it. Editor-
  # gated (BaseController) so experts, not just admins, can work the backlog.
  class IllustrationsController < BaseController
    def index
      rows = Lesson.includes(:path, :course)
                   .sort_by { |lesson| [ lesson.path.position, lesson.position ] }
                   .filter_map do |lesson|
        briefs = lesson.pending_illustration_briefs
        { lesson: lesson, briefs: briefs } if briefs.any?
      end

      @groups = rows.group_by { |row| row[:lesson].path }
      @pending_count = rows.sum { |row| row[:briefs].size }
      @lesson_count = rows.size
    end
  end
end
