require "test_helper"

class CourseTest < ActiveSupport::TestCase
  # Validations

  test "valid with required attributes" do
    course = Course.new(path: paths(:electrician), title: "Курс", slug: "novyy-kurs")
    assert course.valid?
  end

  test "invalid without title" do
    course = Course.new(path: paths(:electrician), slug: "no-title-course")
    assert_not course.valid?
    assert course.errors[:title].any?
  end

  test "invalid without slug" do
    course = Course.new(path: paths(:electrician), title: "No Slug")
    assert_not course.valid?
    assert course.errors[:slug].any?
  end

  test "invalid without path" do
    course = Course.new(title: "Orphan", slug: "orphan-course")
    assert_not course.valid?
    assert course.errors[:path].any?
  end

  test "slug must be unique" do
    course = Course.new(path: paths(:electrician), title: "Dup", slug: courses(:el_basics).slug)
    assert_not course.valid?
    assert course.errors[:slug].any?
  end

  test "slug rejects invalid format" do
    course = Course.new(path: paths(:electrician), title: "T", slug: "BAD SLUG")
    assert_not course.valid?
    assert course.errors[:slug].any?
  end

  test "invalid with unknown status" do
    course = Course.new(path: paths(:electrician), title: "Bad", slug: "bad-status-course", status: "archived")
    assert_not course.valid?
    assert course.errors[:status].any?
  end

  # Scopes

  test ".published returns only published courses" do
    assert_includes Course.published, courses(:el_basics)
    assert_not_includes Course.published, courses(:el_relay_soon)
    assert_not_includes Course.published, courses(:draft_course)
  end

  test ".listable includes coming_soon but not draft" do
    assert_includes Course.listable, courses(:el_relay_soon)
    assert_not_includes Course.listable, courses(:draft_course)
  end

  test "coming_soon? reflects status" do
    assert courses(:el_relay_soon).coming_soon?
    refute courses(:el_basics).coming_soon?
  end

  # Associations / counter cache

  test "has many lessons" do
    assert_equal 2, courses(:el_basics).lessons.count
  end

  test "destroying course destroys its lessons" do
    assert_difference "Lesson.count", -2 do
      courses(:el_basics).destroy
    end
  end

  test "lessons_count counter tracks lesson creation" do
    course = courses(:el_pue)
    before = course.lessons_count
    course.lessons.create!(title: "Новый", slug: "cc-course-lesson", position: 99)
    assert_equal before + 1, course.reload.lessons_count
  end

  # to_param

  test "to_param returns slug" do
    assert_equal "elektrik-osnovy", courses(:el_basics).to_param
  end
end
