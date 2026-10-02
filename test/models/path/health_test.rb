require "test_helper"

class Path::HealthTest < ActiveSupport::TestCase
  test "a learner who went quiet stalls on the lesson they ticked last" do
    member = users(:member)
    member.lesson_completions.create!(lesson: lessons(:pteep), created_at: 30.days.ago)
    member.lesson_completions.create!(lesson: lessons(:gruppy_dopuska), created_at: 20.days.ago)

    health = paths(:electrician).health

    assert_equal 1, health.learners
    assert_equal 0, health.active_learners
    assert_equal [ lessons(:gruppy_dopuska), 1 ], health.stall
  end

  test "an active learner has not stalled" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    health = paths(:electrician).health

    assert_equal 1, health.active_learners
    assert_nil health.stall
  end

  test "staff ticking through lessons are not learners" do
    users(:editor).lesson_completions.create!(lesson: lessons(:pteep), created_at: 20.days.ago)

    assert_equal 0, paths(:electrician).health.learners
  end

  test "pending edits count only this profession's lessons" do
    expected = LessonSuggestion.pending.joins(:lesson).where(lessons: { path_id: paths(:electrician).id }).count

    assert_equal expected, paths(:electrician).health.pending_suggestions
    assert_operator expected, :<, LessonSuggestion.pending.count
  end
end
