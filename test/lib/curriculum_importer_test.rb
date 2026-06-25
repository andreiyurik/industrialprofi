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

  test "new content without an explicit status defaults to draft" do
    dir = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(dir, "draftprof", "01-c"))
    File.write(File.join(dir, "draftprof", "path.yml"),
               %(title: "Черновая профессия"\ndescription: "Без статуса."\nposition: 50\n))
    File.write(File.join(dir, "draftprof", "01-c", "course.yml"),
               %(title: "Курс"\nslug: "draft-course-x"\ndescription: "Без статуса."\nposition: 1\n))

    CurriculumImporter.run(dir: dir, io: StringIO.new)

    assert_equal "draft", Path.find_by!(slug: "draftprof").status
    assert_equal "draft", Course.find_by!(slug: "draft-course-x").status
  ensure
    FileUtils.remove_entry(dir)
  end

  test "refuses to move a lesson whose slug already belongs to another profession" do
    dir = Dir.mktmpdir
    %w[prof-a prof-b].each do |slug|
      section = File.join(dir, slug, "01-course", "01-section")
      FileUtils.mkdir_p(section)
      File.write(File.join(dir, slug, "path.yml"), %(title: "#{slug}"\ndescription: "x"\nposition: 80\n))
      File.write(File.join(dir, slug, "01-course", "course.yml"),
                 %(title: "Курс #{slug}"\nslug: "course-#{slug}"\ndescription: "x"\nposition: 1\n))
      File.write(File.join(section, "section.yml"), %(title: "Раздел"\n))
      File.write(File.join(section, "vvedenie.md"),
                 %(---\ntitle: "Введение"\nkind: lesson\n---\nЗачем.\n\n---\nТело.\n))
    end

    error = assert_raises(ImportUpsert::CrossPathConflict) do
      CurriculumImporter.run(dir: dir, io: StringIO.new)
    end
    assert_includes error.message, "vvedenie"
    assert_equal "prof-a", Lesson.find_by!(slug: "vvedenie").path.slug,
      "the lesson stays with the profession that created it"
  ensure
    FileUtils.remove_entry(dir)
  end

  test "a duplicate lesson slug within one profession aborts it atomically" do
    dir = Dir.mktmpdir
    %w[01-section 02-section].each do |section|
      section_dir = File.join(dir, "dupprof", "01-course", section)
      FileUtils.mkdir_p(section_dir)
      File.write(File.join(section_dir, "section.yml"), %(title: "#{section}"\n))
      File.write(File.join(section_dir, "vvedenie.md"),
                 %(---\ntitle: "Введение"\nkind: lesson\n---\nЗачем.\n\n---\nТело.\n))
    end
    File.write(File.join(dir, "dupprof", "path.yml"), %(title: "Дубль"\ndescription: "x"\nposition: 80\n))
    File.write(File.join(dir, "dupprof", "01-course", "course.yml"),
               %(title: "Курс"\nslug: "dup-course"\ndescription: "x"\nposition: 1\n))

    assert_raises(ImportUpsert::DuplicateSlugConflict) do
      CurriculumImporter.run(dir: dir, io: StringIO.new)
    end
    assert_not Path.exists?(slug: "dupprof"),
      "the whole profession rolls back — no half-written tree"
  ensure
    FileUtils.remove_entry(dir)
  end

  test "an admin edit to a course title survives re-import (digest freeze)" do
    import
    course = Course.find_by!(slug: "test-course-x")
    course.update!(title: "Курс, переименованный экспертом")

    import # the yml still says "Тестовый курс"

    assert_equal "Курс, переименованный экспертом", course.reload.title,
      "a human edit changes the digested fields, freezing the row from re-import"
  end

  test "only: imports a single profession and leaves the rest untouched" do
    dir = Dir.mktmpdir
    %w[prof-a prof-b].each_with_index do |slug, i|
      FileUtils.mkdir_p(File.join(dir, slug))
      File.write(File.join(dir, slug, "path.yml"),
                 %(title: "#{slug}"\ndescription: "x"\nposition: #{90 + i}\n))
    end

    CurriculumImporter.run(dir: dir, only: "prof-a", io: StringIO.new)

    assert Path.exists?(slug: "prof-a")
    assert_not Path.exists?(slug: "prof-b")
  ensure
    FileUtils.remove_entry(dir)
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
