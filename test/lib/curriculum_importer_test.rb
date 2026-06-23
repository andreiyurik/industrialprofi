require "test_helper"
require "tmpdir"
require "stringio"

class CurriculumImporterTest < ActiveSupport::TestCase
  setup do
    @dir = Dir.mktmpdir
    write_tree(lesson_title: "Тестовый урок", resource_url: "https://example.com/g1")
  end

  teardown { FileUtils.remove_entry(@dir) }

  test "creates the full tree on first import, stamped as seed" do
    import

    path = Path.find_by!(slug: "testprof")
    assert_equal "seed", path.origin
    assert path.imported_digest.present?

    lesson = Lesson.find_by!(slug: "test-lesson-x")
    assert_equal "Тестовый урок", lesson.title
    assert_equal "Описание урока.", lesson.description
    assert_equal path, lesson.path
    assert_equal Course.find_by!(slug: "test-course-x"), lesson.course
    assert_equal "seed", lesson.origin

    resource = lesson.resources.sole
    assert_equal "seed", resource.origin
    assert resource.required?
  end

  test "refreshes a pristine lesson on re-import" do
    import
    write_tree(lesson_title: "Обновлённый урок", resource_url: "https://example.com/g1")
    import

    assert_equal "Обновлённый урок", Lesson.find_by!(slug: "test-lesson-x").title
  end

  test "never overwrites a lesson a human has edited" do
    import
    lesson = Lesson.find_by!(slug: "test-lesson-x")
    lesson.revise!(section: "body", html: "<p>правка эксперта</p>",
                   editor_name: "Эксперт", edit_reason: "уточнение", source: "suggestion")

    write_tree(lesson_title: "ИИ-перезапись", resource_url: "https://example.com/g1")
    counts = import

    assert_equal "Тестовый урок", lesson.reload.title
    assert_equal 1, counts["lessons_frozen"]
  end

  test "never overwrites a human-authored path" do
    import
    path = Path.find_by!(slug: "testprof")
    path.update!(origin: "human", title: "Авторская профессия")

    import

    assert_equal "Авторская профессия", path.reload.title
  end

  test "leaves human-owned resources alone" do
    import
    resource = Lesson.find_by!(slug: "test-lesson-x").resources.sole
    resource.update!(origin: "human", url: "https://example.com/expert-pick")

    import

    assert_equal "https://example.com/expert-pick", resource.reload.url
  end

  private
    def import
      CurriculumImporter.run(dir: @dir, io: StringIO.new)
    end

    def write_tree(lesson_title:, resource_url:)
      section_dir = File.join(@dir, "testprof", "01-test-course", "01-section")
      FileUtils.mkdir_p(section_dir)

      File.write(File.join(@dir, "testprof", "path.yml"), <<~YAML)
        title: "Тестовая профессия"
        description: "Профессия для теста импортёра."
        position: 99
        status: published
      YAML

      File.write(File.join(@dir, "testprof", "01-test-course", "course.yml"), <<~YAML)
        title: "Тестовый курс"
        slug: "test-course-x"
        description: "Курс для теста."
        position: 1
        status: published
      YAML

      File.write(File.join(section_dir, "section.yml"), %(title: "Тестовый раздел"\n))

      File.write(File.join(section_dir, "test-lesson-x.md"), <<~MD)
        ---
        title: "#{lesson_title}"
        kind: lesson
        resources:
          - title: "ГОСТ 1"
            url: "#{resource_url}"
            kind: document
            required: true
        ---
        Описание урока.

        ---
        Тело урока.

        ## Задание
        Сделать что-то.
      MD
    end
end
