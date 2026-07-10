require "test_helper"
require "tmpdir"
require "stringio"

class CurriculumExporterTest < ActiveSupport::TestCase
  setup { @dir = Dir.mktmpdir }
  teardown { FileUtils.remove_entry(@dir) }

  test "writes the tree the importer reads" do
    root = CurriculumExporter.run(paths(:electrician), dir: @dir, io: StringIO.new)

    assert root.join("path.yml").exist?
    assert_equal "Электрик", YAML.safe_load_file(root.join("path.yml"))["title"]
    assert root.join("01-elektrik-osnovy/course.yml").exist?

    lesson_md = root.join("01-elektrik-osnovy/01-section/pteep-osnovy.md")
    data = CurriculumImporter.parse_lesson(lesson_md)
    assert_equal "ПТЭЭП: основы эксплуатации", data["title"]
    assert_equal "Основной документ по эксплуатации", data["description"]
    assert_equal "Прочитайте главы 1.1–1.4", data["task"]
    assert_equal "ПТЭЭП — полный текст", data["resources"].first["title"]
  end

  test "export → import into a clean instance reproduces the profession" do
    original = paths(:electrician)
    resources(:zazemlenie_gost).update!(note: "Только раздел 542")
    lessons_before = original.lessons.ordered.map { |lesson|
      [ lesson.slug, lesson.title, lesson.stage, lesson.course.slug, lesson.body.to_s.strip ]
    }

    root = CurriculumExporter.run(original, dir: @dir, io: StringIO.new)
    original.destroy!

    CurriculumImporter.run(dir: @dir, io: StringIO.new)
    reimported = Path.find_by!(slug: "elektrik")

    assert_equal "Электрик", reimported.title
    assert_equal lessons_before, reimported.lessons.ordered.map { |lesson|
      [ lesson.slug, lesson.title, lesson.stage, lesson.course.slug, lesson.body.to_s.strip ]
    }
    assert_equal "Только раздел 542",
      reimported.lessons.find_by!(slug: "pue-zazemlenie").resources.sole.note
  end

  test "splits a drag-reordered stage into ordered section runs" do
    course = courses(:el_basics)
    # Fixture order within the stage: pteep-osnovy (pos 1), gruppy-dopuska (pos 2) —
    # slugs DESCEND while positions ascend, so one alphabetical run is impossible.
    root = CurriculumExporter.run(paths(:electrician), dir: @dir, io: StringIO.new)
    course_dir = root.join("01-#{course.slug}")

    sections = course_dir.glob("*/section.yml").sort
    assert_operator sections.size, :>=, 2
    assert_equal [ "Электробезопасность и допуски" ] * 2,
      sections.first(2).map { |yml| YAML.safe_load_file(yml)["title"] }
  end
end
