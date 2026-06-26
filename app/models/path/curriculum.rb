# The curriculum-shaping behaviour of a profession: applying a new order to its
# courses and lessons after a drag in the builder. Kept here (not in a
# controller) so the global-position invariant lives next to the model that owns
# it and stays unit-testable. Mirrors Fizzy's Column::Positioned concern.
module Path::Curriculum
  extend ActiveSupport::Concern

  # Apply a new lesson order from the builder. `ordered` is EVERY lesson in its
  # new visual order, each tagged with the course it now sits under and its
  # stage, so one call covers both reordering and moving a lesson to another
  # course. Positions are global within the profession, so we renumber 1..N.
  # Assigning the course association (not the raw id) keeps lessons_count and the
  # denormalized path_id in sync; the +changed?+ guard skips untouched rows.
  def reorder_lessons!(ordered)
    lessons_by_id = lessons.index_by(&:id)
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

  # Apply a new course order. Lesson positions are global within the path, so
  # reordering courses also renumbers every lesson in the new course order —
  # otherwise the continuous prev/next flow (which follows lesson.position) would
  # break. Position-only writes → update_column (no counter caches or IndexNow
  # pings ride along).
  # Rename a section within a course. There's no Stage model — a section is just
  # the shared `stage` label on contiguous lessons — so this updates that label on
  # every lesson in the course carrying it. A human-authored rename, so those
  # lessons take human ownership (importer leaves them alone). Blank `to` clears
  # the section.
  def rename_stage!(course_id:, from:, to:)
    course = courses.find(course_id)
    course.lessons.where(stage: from.presence).find_each do |lesson|
      lesson.update!(stage: to.presence, origin: "human")
    end
  end

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
