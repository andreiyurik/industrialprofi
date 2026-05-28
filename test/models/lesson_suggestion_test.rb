require "test_helper"

class LessonSuggestionTest < ActiveSupport::TestCase
  # Validations

  test "valid with required attributes" do
    suggestion = LessonSuggestion.new(
      lesson: lessons(:pteep),
      body_markdown: "New content",
      author_name: "Test Author"
    )
    assert suggestion.valid?
  end

  test "invalid without any body content" do
    suggestion = LessonSuggestion.new(lesson: lessons(:pteep), author_name: "Author")
    assert_not suggestion.valid?
    assert suggestion.errors[:rich_body].any?
  end

  test "invalid without author_name" do
    suggestion = LessonSuggestion.new(lesson: lessons(:pteep), body_markdown: "Content")
    assert_not suggestion.valid?
    assert suggestion.errors[:author_name].any?
  end

  test "invalid without lesson" do
    suggestion = LessonSuggestion.new(body_markdown: "Content", author_name: "Author")
    assert_not suggestion.valid?
    assert suggestion.errors[:lesson].any?
  end

  test "section defaults to body" do
    suggestion = LessonSuggestion.new
    assert_equal "body", suggestion.section
  end

  test "status defaults to pending" do
    suggestion = LessonSuggestion.new
    assert_equal "pending", suggestion.status
  end

  test "section must be valid" do
    suggestion = LessonSuggestion.new(
      lesson: lessons(:pteep), body_markdown: "X", author_name: "Y", section: "invalid"
    )
    assert_not suggestion.valid?
  end

  test "status must be valid" do
    suggestion = LessonSuggestion.new(
      lesson: lessons(:pteep), body_markdown: "X", author_name: "Y", status: "invalid"
    )
    assert_not suggestion.valid?
  end

  # Scopes

  test "pending scope returns only pending" do
    assert LessonSuggestion.pending.all? { |s| s.status == "pending" }
  end

  # Associations

  test "belongs to lesson" do
    assert_equal lessons(:pteep), lesson_suggestions(:pending_suggestion).lesson
  end

  # Staleness

  test "not stale without a base snapshot" do
    refute lesson_suggestions(:pending_suggestion).stale?
  end

  test "not stale when section matches the base snapshot" do
    lesson = lessons(:pteep)
    suggestion = lesson.lesson_suggestions.create!(
      body_markdown: "Правка", author_name: "A", section: "body",
      base_content: lesson.section_html("body")
    )
    refute suggestion.stale?
  end

  test "stale when section changed since submission" do
    lesson = lessons(:pteep)
    suggestion = lesson.lesson_suggestions.create!(
      body_markdown: "Правка", author_name: "A", section: "body",
      base_content: "<p>Совсем другой исходный текст</p>"
    )
    assert suggestion.stale?
  end
end
