require "test_helper"
require "tmpdir"
require "stringio"

class CurriculumPackTest < ActiveSupport::TestCase
  setup { @dir = Dir.mktmpdir }
  teardown { FileUtils.remove_entry(@dir) }

  test "a zip of the exported tree round-trips into a draft profession" do
    original = paths(:electrician)
    noted = resources(:zazemlenie_gost)
    noted.update!(note: "Только раздел 542")
    noted_lesson_slug, noted_title = noted.lesson.slug, noted.title
    lessons_before = original.lessons.ordered.map { |lesson| [ lesson.slug, lesson.title, lesson.stage ] }

    root = CurriculumExporter.run(original, dir: @dir, io: StringIO.new)
    zip = zip_tree(root, prefix: "elektrik")
    original.destroy!

    pack = CurriculumPack.parse(StringIO.new(zip))
    assert pack.valid?, pack.errors.inspect

    document = CurriculumDocument.parse(pack.to_yaml)
    assert document.valid?, document.errors.inspect
    document.import!(author: users(:admin))
    assert document.valid?, document.errors.inspect

    reimported = Path.find_by!(slug: "elektrik")
    assert_equal "draft", reimported.status, "packs land as drafts for the trust ladder"
    assert_equal lessons_before,
                 reimported.lessons.ordered.map { |lesson| [ lesson.slug, lesson.title, lesson.stage ] }
    assert_equal "Только раздел 542",
                 reimported.lessons.find_by!(slug: noted_lesson_slug)
                           .resources.find_by!(title: noted_title).note
    assert_equal "RCD", reimported.lessons.find_by!(slug: "pue-zazemlenie").glossary_terms.find_by!(abbr: "УЗО").analog,
                 "a pack's terms ride through the document engine too"
  end

  test "landing.yml rides the pack; a cover is reported, not imported" do
    original = paths(:electrician)
    original.update!(about: "Кто это.", pros_text: "Востребован")
    original.cover.attach(io: File.open(Rails.root.join("test/fixtures/files/cover.png")), filename: "cover.png", content_type: "image/png")

    root = CurriculumExporter.run(original, dir: @dir, io: StringIO.new)
    pack = CurriculumPack.parse(StringIO.new(zip_tree(root, prefix: "elektrik")))
    original.destroy!
    assert pack.valid?, pack.errors.inspect

    document = CurriculumDocument.parse(pack.to_yaml)
    assert_includes pack.warnings, :cover_skipped, "warnings are collected while building the document"
    document.import!(author: users(:admin))
    reimported = Path.find_by!(slug: "elektrik")
    assert_equal "Кто это.", reimported.about
    assert_equal [ "Востребован" ], reimported.pros
    assert_not reimported.cover.attached?
  end

  test "path and course emblems ride the pack" do
    original = paths(:electrician)
    original.update!(icon: "atom-light")
    course = original.courses.first
    course.update!(icon: "camera-light")

    root = CurriculumExporter.run(original, dir: @dir, io: StringIO.new)
    pack = CurriculumPack.parse(StringIO.new(zip_tree(root, prefix: "elektrik")))
    original.destroy!

    document = CurriculumDocument.parse(pack.to_yaml)
    document.import!(author: users(:admin))
    assert document.valid?, document.errors.inspect

    reimported = Path.find_by!(slug: "elektrik")
    assert_equal "atom-light", reimported.icon
    assert_equal "camera-light", reimported.courses.find_by!(slug: course.slug).icon
  end

  test "a zip made from inside the profession directory falls back to the title slug" do
    root = CurriculumExporter.run(paths(:electrician), dir: @dir, io: StringIO.new)
    pack = CurriculumPack.parse(StringIO.new(zip_tree(root)))

    assert pack.valid?, pack.errors.inspect
    data = YAML.safe_load(pack.to_yaml)
    assert_nil data["path"]["slug"] # CurriculumDocument derives elektrik from «Электрик»
    assert_equal "Электрик", data["path"]["title"]
  end

  test "refuses garbage that is not a zip" do
    pack = CurriculumPack.parse(StringIO.new("это не архив"))

    assert_not pack.valid?
    assert_includes pack.errors, :not_a_zip
  end

  test "refuses an archive without path.yml" do
    zip = build_zip("readme.txt" => "hello")
    pack = CurriculumPack.parse(StringIO.new(zip))

    assert_nil pack.to_yaml
    assert_includes pack.errors, :no_path_yml
  end

  test "refuses a pack from a newer format" do
    zip = build_zip("elektrik/pack.yml" => { "format" => CurriculumPack::FORMAT + 1 }.to_yaml,
                    "elektrik/path.yml" => { "title" => "Электрик" }.to_yaml)
    pack = CurriculumPack.parse(StringIO.new(zip))

    assert_not pack.valid?
    assert_includes pack.errors, :format_unsupported
  end

  test "warns when the pack carries images (not imported yet)" do
    root = CurriculumExporter.run(paths(:electrician), dir: @dir, io: StringIO.new)
    zip = zip_tree(root, prefix: "elektrik", extra: { "elektrik/images/shchitok.webp" => "binary" })
    pack = CurriculumPack.parse(StringIO.new(zip))

    assert pack.valid?
    assert pack.to_yaml.present?
    assert_includes pack.warnings, :images_skipped
  end

  private

  def zip_tree(root, prefix: nil, extra: {})
    files = Pathname(root).glob("**/*").select(&:file?).to_h do |file|
      rel = file.relative_path_from(root).to_s
      [ prefix ? "#{prefix}/#{rel}" : rel, file.read ]
    end
    build_zip(files.merge(extra))
  end

  def build_zip(files)
    Zip::OutputStream.write_buffer do |zip|
      files.each do |name, content|
        zip.put_next_entry(name)
        zip.write(content)
      end
    end.string
  end
end
