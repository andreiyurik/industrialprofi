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
end
