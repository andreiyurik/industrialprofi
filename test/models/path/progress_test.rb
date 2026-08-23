require "test_helper"

class Path::ProgressTest < ActiveSupport::TestCase
  test "a guest has a null progress that still knows where to start" do
    progress = Path::Progress.for(paths(:electrician), nil)

    assert progress.guest?
    assert_not progress.started?
    assert_empty progress.completed_ids
    assert_equal 0, progress.completed_count
    assert_equal({}, progress.done_by_course)
    assert_equal lessons(:pteep), progress.next_lesson
  end

  test "a member who has done nothing here has not started" do
    progress = Path::Progress.for(paths(:electrician), users(:member))

    assert_not progress.guest?
    assert_not progress.started?
    assert_equal lessons(:pteep), progress.next_lesson
  end

  test "completions drive started, per-course counts and the next lesson" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))
    progress = Path::Progress.for(paths(:electrician), users(:member))

    assert progress.started?
    assert progress.completed?(lessons(:pteep))
    assert_not progress.completed?(lessons(:gruppy_dopuska))
    assert_equal 1, progress.completed_count
    assert_equal({ courses(:el_basics).id => 1 }, progress.done_by_course)
    assert_equal lessons(:gruppy_dopuska), progress.next_lesson
  end
end
