require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email address" do
    user = User.create!(name: "Тест", email_address: "  USER@Example.COM ", password: "password123")
    assert_equal "user@example.com", user.email_address
  end

  test "requires unique email" do
    user = User.new(name: "Тест", email_address: users(:member).email_address, password: "password123")
    assert_not user.valid?
  end

  test "requires password of at least 8 characters" do
    user = User.new(name: "Тест", email_address: "short@example.com", password: "1234567")
    assert_not user.valid?
  end

  test "defaults to member role" do
    user = User.new
    assert user.member?
    assert_not user.can_administer?
  end

  test "administrator can administer" do
    assert users(:admin).can_administer?
  end

  test "completed? reflects lesson completions" do
    user = users(:member)
    lesson = lessons(:pteep)

    assert_not user.completed?(lesson)
    user.lesson_completions.create!(lesson: lesson)
    assert user.completed?(lesson)
  end

  test "completed_lesson_ids_for scopes to the path" do
    user = users(:member)
    user.lesson_completions.create!(lesson: lessons(:pteep))

    assert_equal Set[lessons(:pteep).id], user.completed_lesson_ids_for(paths(:electrician))
    assert_empty user.completed_lesson_ids_for(paths(:welder))
  end

  test "next_lesson_in returns first uncompleted lesson in position order" do
    user = users(:member)
    path = paths(:electrician)

    assert_equal lessons(:pteep), user.next_lesson_in(path)

    user.lesson_completions.create!(lesson: lessons(:pteep))
    assert_equal lessons(:gruppy_dopuska), user.next_lesson_in(path)
  end

  test "started_paths lists only paths with completions" do
    user = users(:member)
    assert_empty user.started_paths

    user.lesson_completions.create!(lesson: lessons(:pteep))
    assert_equal [ paths(:electrician) ], user.started_paths
  end

  test "focus_path is the path of the most recent completion" do
    user = users(:member)
    assert_nil user.focus_path

    user.lesson_completions.create!(lesson: lessons(:pteep), created_at: 2.days.ago)
    assert_equal paths(:electrician), user.focus_path

    user.lesson_completions.create!(lesson: lessons(:svarka_intro), created_at: 1.hour.ago)
    assert_equal paths(:welder), user.focus_path
  end

  test "activity_by_day merges completions and journal entries" do
    user = users(:member)
    user.lesson_completions.create!(lesson: lessons(:pteep))
    user.lesson_completions.create!(lesson: lessons(:zazemlenie))
    user.journal_entries.create!(body: "Запись в дневнике")

    activity = user.activity_by_day(since: 1.week.ago.to_date)
    assert_equal 3, activity[Date.current]
  end

  test "activity_by_day ignores actions before the window" do
    user = users(:member)
    user.lesson_completions.create!(lesson: lessons(:pteep), created_at: 1.year.ago)

    assert_empty user.activity_by_day(since: 1.week.ago.to_date)
  end

  test "needs_learning_reminder? only after a week of silence" do
    user = users(:member)
    assert_not user.needs_learning_reminder?, "no activity at all — nothing to continue"

    completion = user.lesson_completions.create!(lesson: lessons(:pteep), created_at: 1.day.ago)
    assert_not user.needs_learning_reminder?, "recently active"

    completion.update!(created_at: 10.days.ago)
    assert user.needs_learning_reminder?
  end

  test "needs_learning_reminder? nudges once per stall, again after a new stall" do
    user = users(:member)
    user.lesson_completions.create!(lesson: lessons(:pteep), created_at: 20.days.ago)

    user.update!(reminded_at: 15.days.ago)
    assert_not user.needs_learning_reminder?, "already nudged for this stall"

    user.lesson_completions.create!(lesson: lessons(:gruppy_dopuska), created_at: 8.days.ago)
    assert user.needs_learning_reminder?, "worked again after the nudge, then stalled anew"
  end

  test "needs_learning_reminder? respects the opt-out and a finished path" do
    user = users(:member)
    user.lesson_completions.create!(lesson: lessons(:pteep), created_at: 10.days.ago)

    user.update!(reminder_emails: false)
    assert_not user.needs_learning_reminder?

    user.update!(reminder_emails: true)
    paths(:electrician).lessons.find_each do |lesson|
      user.lesson_completions.find_or_create_by!(lesson: lesson) { |c| c.created_at = 10.days.ago }
    end
    assert_not user.needs_learning_reminder?, "nothing left to continue in the focus path"
  end
end
