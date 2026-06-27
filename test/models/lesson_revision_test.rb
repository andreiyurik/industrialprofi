require "test_helper"

class LessonRevisionTest < ActiveSupport::TestCase
  setup { @lesson = lessons(:pteep) }

  test "valid revision" do
    revision = build_revision
    assert revision.valid?
  end

  test "requires a known section" do
    revision = build_revision(section: "nope")
    assert_not revision.valid?
  end

  test "requires a known source" do
    revision = build_revision(source: "nope")
    assert_not revision.valid?
  end

  test "is immutable once persisted" do
    revision = build_revision
    revision.save!
    revision.edit_reason = "tampered"
    assert_raises(ActiveRecord::ReadOnlyRecord) { revision.save! }
  end

  test "creating a revision bumps the lesson counter" do
    assert_difference -> { @lesson.reload.lesson_revisions_count }, 1 do
      build_revision.save!
    end
  end

  test "creating a revision touches the lesson, busting its content cache" do
    before = @lesson.updated_at
    travel 1.second do
      build_revision.save!
    end
    assert_operator @lesson.reload.updated_at, :>, before
  end

  test "ordered scope returns newest version first" do
    @lesson.record_revision!(section: "body", before: "a", after: "b", editor_name: "X", edit_reason: nil, source: "admin")
    @lesson.record_revision!(section: "body", before: "b", after: "c", editor_name: "X", edit_reason: nil, source: "admin")
    assert_equal [ 2, 1 ], @lesson.lesson_revisions.ordered.map(&:version)
  end

  private

  def build_revision(**attrs)
    @lesson.lesson_revisions.build({
      version: 1, section: "body", content_before: "old", content_after: "new",
      editor_name: "Иван", source: "suggestion"
    }.merge(attrs))
  end
end
