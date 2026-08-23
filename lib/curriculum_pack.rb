require "yaml"
require "zip"

# Reads an uploaded profession pack — a .zip of the same YAML/Markdown tree
# CurriculumExporter writes and CurriculumImporter reads — and re-serializes it
# as the single YAML document CurriculumDocument understands. The zip is only
# transport, the tree is the format, the document pipeline is the one engine:
# an uploaded pack gets the exact same dry-run preview, draft status and
# freeze-safety as a pasted draft.
#
# Everything happens in memory (no extraction to disk), which is also the
# zip-slip defense: entry names are treated as keys, never as filesystem paths.
class CurriculumPack
  # Newest pack format this build understands (pack.yml → "format").
  FORMAT = 1

  MAX_BYTES = 20.megabytes      # the upload itself
  MAX_ENTRY_BYTES = 5.megabytes # any single file, uncompressed (zip bombs)
  MAX_ENTRIES = 2_000

  attr_reader :errors, :warnings

  def self.parse(io) = new(io)

  def initialize(io)
    @errors = []
    @warnings = []
    @entries = read_entries(io)
    check_manifest if @errors.empty?
  end

  def valid? = @errors.empty?

  # The pack as a CurriculumDocument YAML string, or nil when unreadable.
  def to_yaml
    return nil unless valid?

    document = build_document
    valid? ? document.to_yaml : nil
  end

  private

  def read_entries(io)
    data = io.read
    if data.bytesize > MAX_BYTES
      @errors << :too_large
      return {}
    end

    entries = {}
    Zip::File.open_buffer(data) do |zip|
      zip.each do |entry|
        next unless entry.file?
        if entries.size >= MAX_ENTRIES
          @errors << :too_many_files
          break
        end
        if entry.size > MAX_ENTRY_BYTES
          @errors << :entry_too_large
          break
        end
        entries[entry.name] = entry.get_input_stream.read.force_encoding(Encoding::UTF_8)
      end
    end
    entries
  rescue StandardError
    @errors << :not_a_zip
    {}
  end

  # pack.yml is optional (older exports); a pack from a NEWER format is refused
  # rather than half-understood.
  def check_manifest
    manifest = yaml_at(names.find { |name| File.basename(name) == "pack.yml" })
    return if manifest.nil?

    @errors << :format_unsupported if manifest["format"].to_i > FORMAT
  end

  def build_document
    path_yml = names.select { |name| File.basename(name) == "path.yml" }.min_by(&:length)
    if path_yml.nil?
      @errors << :no_path_yml
      return nil
    end

    root = File.dirname(path_yml) # "." when path.yml sits at the zip root
    meta = yaml_at(path_yml) || {}
    @warnings << :images_skipped if names.any? { |name| name.start_with?(prefixed(root, "images/")) }
    # Covers are not part of the pack format at all — a hand-built zip that
    # still carries one is told so, and the editor adds it in the profession form.
    @warnings << :cover_skipped if names.any? { |name| name.match?(%r{\A#{Regexp.escape(prefixed(root, "cover."))}(jpe?g|png|webp)\z}) }
    landing_yml = names.find { |name| name == prefixed(root, "landing.yml") }

    {
      "path" => { "slug" => path_slug(root), "title" => meta["title"],
                  "description" => meta["description"], "icon" => meta["icon"],
                  "landing" => (yaml_at(landing_yml) if landing_yml) }.compact,
      "courses" => courses(root)
    }
  end

  # The exporter's tree carries the profession slug as its root directory name;
  # a zip made from inside that directory falls back to the title-derived slug.
  def path_slug(root)
    File.basename(root) unless root == "."
  end

  def courses(root)
    child_ymls(root, "course.yml").map do |course_dir, meta|
      {
        "slug" => meta["slug"], "title" => meta["title"], "description" => meta["description"],
        "icon" => meta["icon"], "sections" => sections(course_dir)
      }.compact
    end
  end

  def sections(course_dir)
    child_ymls(course_dir, "section.yml").map do |section_dir, meta|
      { "title" => meta["title"], "lessons" => lessons(section_dir) }.compact
    end
  end

  def lessons(section_dir)
    names.select { |name| File.dirname(name) == section_dir && name.end_with?(".md") }
         .sort.map do |name|
      data = CurriculumImporter.parse_lesson_content(@entries[name])
      data.merge("slug" => File.basename(name, ".md")).compact
    rescue StandardError
      @errors << "#{File.basename(name)}: не удалось разобрать статью"
      {}
    end
  end

  # `<dir>/<child>/<filename>` entries, sorted by name — mirrors the seed
  # importer's Dir.glob(...).sort ordering, which is what fixes course/section order.
  def child_ymls(dir, filename)
    names.select { |name| File.basename(name) == filename && File.dirname(File.dirname(name)) == dir }
         .sort.map { |name| [ File.dirname(name), yaml_at(name) || {} ] }
  end

  def prefixed(dir, rest) = dir == "." ? rest : "#{dir}/#{rest}"

  def names = @entries.keys

  def yaml_at(name)
    return nil if name.nil? || @entries[name].nil?

    YAML.safe_load(@entries[name], permitted_classes: [ Symbol, Date, Time ])
  rescue Psych::Exception
    @errors << "#{File.basename(name)}: не удалось разобрать YAML"
    nil
  end
end
