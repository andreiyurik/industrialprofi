require "yaml"

CURRICULUM_DIR = Rails.root.join("db/seeds/curriculum")

def parse_lesson(file_path)
  content = File.read(file_path)
  frontmatter, body = content.split(/^---\s*$/, 3).reject(&:blank?)

  meta = YAML.safe_load(frontmatter, permitted_classes: [ Symbol ])
  parts = body.split(/^---\s*$/, 2)

  description = parts[0].strip
  rest = parts[1]&.strip || ""

  if rest.match?(/^## Задание/m)
    body_text, task = rest.split(/^## Задание\s*$/m, 2)
    body_text = body_text&.strip
    task = task&.strip
  else
    body_text = rest.presence
    task = nil
  end

  meta.merge("description" => description, "body" => body_text, "task" => task)
end

created_paths = 0
created_lessons = 0
created_resources = 0

Dir.glob(CURRICULUM_DIR.join("*/path.yml")).sort.each do |path_yml|
  path_dir = File.dirname(path_yml)
  path_slug = File.basename(path_dir)
  path_meta = YAML.safe_load_file(path_yml)

  path = Path.find_or_create_by!(slug: path_slug) do |p|
    p.title = path_meta["title"]
    p.description = path_meta["description"]
    p.position = path_meta["position"]
    p.status = path_meta["status"]
    created_paths += 1
  end

  Dir.glob(File.join(path_dir, "*/section.yml")).sort.each do |section_yml|
    section_dir = File.dirname(section_yml)
    section_meta = YAML.safe_load_file(section_yml)
    stage = section_meta["title"]

    Dir.glob(File.join(section_dir, "*.md")).sort.each do |md_file|
      slug = File.basename(md_file, ".md")
      lesson_data = parse_lesson(md_file)

      lesson = path.lessons.find_or_create_by!(slug: slug) do |l|
        l.title = lesson_data["title"]
        l.stage = stage
        l.description = lesson_data["description"]
        l.body = lesson_data["body"]
        l.task = lesson_data["task"]
        l.position = lesson_data["position"]
        l.kind = lesson_data["kind"] || "lesson"
        created_lessons += 1
      end

      (lesson_data["resources"] || []).each_with_index do |res, i|
        lesson.resources.find_or_create_by!(title: res["title"]) do |r|
          r.url = res["url"]
          r.kind = res["kind"]
          r.required = res.fetch("required", false)
          r.country_code = res["country_code"]
          r.position = i + 1
          created_resources += 1
        end
      end
    end
  end
end

puts "Seed complete. Created: #{created_paths} paths, #{created_lessons} lessons, #{created_resources} resources. " \
     "Total: #{Path.count} paths, #{Lesson.count} lessons, #{Resource.count} resources."
