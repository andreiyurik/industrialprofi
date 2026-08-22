# One learner's standing in one profession — the object every hub view reads
# instead of asking `Current.user` five different questions. Built once per
# request; a guest gets the Guest null object, so views never branch on
# signed-in state (exercism's UserTrack::External pattern).
class Path::Progress
  def self.for(path, user)
    user ? new(path, user) : Guest.new(path)
  end

  attr_reader :path, :user

  def initialize(path, user = nil)
    @path = path
    @user = user
  end

  # Started = did at least one lesson here; no join row to create or maintain.
  def started? = completed_ids.any?

  def completed_ids
    @completed_ids ||= user.completed_lesson_ids_for(path)
  end

  def completed?(lesson) = completed_ids.include?(lesson.id)

  def completed_count = completed_ids.size

  # course_id => completed lessons, for each chapter's progress ring.
  def done_by_course
    @done_by_course ||= user.lesson_completions.joins(:lesson)
                            .where(lessons: { path_id: path.id }).group("lessons.course_id").count
  end

  # Where «Продолжить» lands: the first lesson not yet done; nil once the map
  # is finished (the button then hides).
  def next_lesson
    return @next_lesson if defined?(@next_lesson)
    @next_lesson = user.next_lesson_in(path)
  end

  def guest? = false

  class Guest < Path::Progress
    def started? = false
    def completed_ids = Set.new
    def done_by_course = {}
    def next_lesson = path.lessons.ordered.first
    def guest? = true
  end
end
