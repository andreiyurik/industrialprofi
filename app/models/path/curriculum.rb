module Path::Curriculum
  extend ActiveSupport::Concern

  # Assigns the course association, not the raw id, to keep lessons_count and path_id in sync.
  def reorder_lessons!(ordered)
    # Preloaded: each save re-indexes for search, reading course and rich texts.
    lessons_by_id = lessons.includes(:course).with_all_rich_text.index_by(&:id)
    courses_by_id = courses.index_by(&:id)

    transaction do
      ordered.each_with_index do |item, index|
        lesson = lessons_by_id[item[:id].to_i] or next
        course = courses_by_id[item[:course_id].to_i] or next
        lesson.course = course
        lesson.position = index + 1
        lesson.stage = item[:stage].presence
        lesson.save! if lesson.changed?
      end
    end
  end

  def rename_stage!(course_id:, from:, to:)
    course = courses.find(course_id)
    course.lessons.with_all_rich_text.where(stage: from.presence).find_each do |lesson|
      lesson.update!(stage: to.presence, origin: "human")
    end
  end

  # update_column: position-only writes, no counter caches or IndexNow pings.
  def reorder_courses!(course_ids)
    courses_by_id = courses.index_by(&:id)

    transaction do
      position = 0
      course_ids.each_with_index do |id, index|
        course = courses_by_id[id.to_i] or next
        course.update_column(:position, index + 1) unless course.position == index + 1
        course.lessons.ordered.each do |lesson|
          position += 1
          lesson.update_column(:position, position) unless lesson.position == position
        end
      end
    end
  end
end
