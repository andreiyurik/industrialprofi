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

created = Hash.new(0)

# Curriculum tree (4 levels):
#   <path>/path.yml
#   <path>/<NN>-<course>/course.yml
#   <path>/<NN>-<course>/<MM>-<section>/section.yml  (title → lesson.stage)
#   <path>/<NN>-<course>/<MM>-<section>/<lesson>.md
# All records are upserted (find_or_initialize + save-if-changed) so re-seeding
# is idempotent AND backfills new columns (e.g. course_id) on existing rows.
Dir.glob(CURRICULUM_DIR.join("*/path.yml")).sort.each do |path_yml|
  path_dir = File.dirname(path_yml)
  path_meta = YAML.safe_load_file(path_yml)

  path = Path.find_or_initialize_by(slug: File.basename(path_dir))
  created[:paths] += 1 if path.new_record?
  path.assign_attributes(
    title: path_meta["title"], description: path_meta["description"],
    position: path_meta["position"], status: path_meta["status"]
  )
  path.save! if path.changed?

  position = 0 # lesson position is GLOBAL within the path (continuous prev/next)

  Dir.glob(File.join(path_dir, "*/course.yml")).sort.each do |course_yml|
    course_dir = File.dirname(course_yml)
    course_meta = YAML.safe_load_file(course_yml)

    course = Course.find_or_initialize_by(slug: course_meta["slug"])
    created[:courses] += 1 if course.new_record?
    course.assign_attributes(
      path: path, title: course_meta["title"], description: course_meta["description"],
      position: course_meta["position"], status: course_meta["status"] || "published"
    )
    course.save! if course.changed?

    Dir.glob(File.join(course_dir, "*/section.yml")).sort.each do |section_yml|
      section_dir = File.dirname(section_yml)
      stage = YAML.safe_load_file(section_yml)["title"]

      Dir.glob(File.join(section_dir, "*.md")).sort.each do |md_file|
        slug = File.basename(md_file, ".md")
        lesson_data = parse_lesson(md_file)
        position += 1

        lesson = Lesson.find_or_initialize_by(slug: slug)
        created[:lessons] += 1 if lesson.new_record?
        lesson.assign_attributes(
          course: course, path: path, stage: stage,
          title: lesson_data["title"], description: lesson_data["description"],
          body: lesson_data["body"], task: lesson_data["task"],
          position: position, kind: lesson_data["kind"] || "lesson"
        )
        lesson.save! if lesson.changed?

        (lesson_data["resources"] || []).each_with_index do |res, i|
          resource = lesson.resources.find_or_initialize_by(title: res["title"])
          created[:resources] += 1 if resource.new_record?
          resource.assign_attributes(
            url: res["url"], kind: res["kind"], required: res.fetch("required", false),
            country_code: res["country_code"], position: i + 1
          )
          resource.save! if resource.changed?
        end
      end
    end
  end
end

# Guarantee counter caches are exact regardless of create/update mix above.
Course.find_each { |c| Course.reset_counters(c.id, :lessons) }
Path.find_each   { |p| Path.reset_counters(p.id, :courses, :lessons) }

puts "Seed complete. Created: #{created[:paths]} paths, #{created[:courses]} courses, " \
     "#{created[:lessons]} lessons, #{created[:resources]} resources. " \
     "Total: #{Path.count} paths, #{Course.count} courses, #{Lesson.count} lessons, #{Resource.count} resources."

# First administrator — admin pages are gated by User#can_administer? now, not
# HTTP Basic. Idempotent: only runs when no administrator exists yet.
if User.administrator.none? && ENV["ADMIN_EMAIL"].present? && ENV["ADMIN_PASSWORD"].present?
  User.create!(
    name: ENV.fetch("ADMIN_NAME", "Admin"),
    email_address: ENV["ADMIN_EMAIL"],
    password: ENV["ADMIN_PASSWORD"],
    role: "administrator"
  )
  puts "Administrator #{ENV["ADMIN_EMAIL"]} created."
end

# Development-only logins, one per role, with fixed well-known credentials.
# Never runs in production: real accounts there come from ENV (above) or console.
if Rails.env.development?
  dev_users = [
    { name: "Dev Админ",        email_address: "admin@example.com", role: "administrator" },
    { name: "Dev Пользователь", email_address: "user@example.com",  role: "member" }
  ]

  dev_users.each do |attrs|
    User.find_or_create_by!(email_address: attrs[:email_address]) do |user|
      user.name = attrs[:name]
      user.role = attrs[:role]
      user.password = "password"
    end
  end

  # Give the member a little progress so dashboards and progress bars have
  # something to show right after `db:seed`.
  member = User.find_by!(email_address: "user@example.com")
  if member.lesson_completions.none?
    Lesson.joins(:path).where(paths: { status: "published" }).order(:path_id, :position).limit(2).each do |lesson|
      member.lesson_completions.find_or_create_by!(lesson: lesson)
    end
  end

  puts <<~LOGINS
    Dev logins (password for both: "password"):
      admin@example.com  — administrator (/admin)
      user@example.com   — member (#{member.lesson_completions.count} lessons completed)
  LOGINS
end
