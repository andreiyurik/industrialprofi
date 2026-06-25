# ─────────────────────────────────────────────────────────────────────────────
# DEV-ЛОГИНЫ (только development; в production аккаунтов отсюда НЕТ).
# Пароль у ВСЕХ один: "password"
#
#   Роль            Логин (email)                    Имя
#   ──────────────  ───────────────────────────────  ─────────────────────────
#   администратор   admin@example.com                Dev Админ
#   участник        user@example.com                 Dev Пользователь
#
#   администратор   sergey.admin@example.com         Сергей Ковалёв
#   администратор   olga.admin@example.com           Ольга Морозова
#
#   эксперт         viktor.expert@example.com        Виктор Селезнёв   (elektrik)
#   эксперт         dmitry.expert@example.com        Дмитрий Лагутин   (inzhener-asu-tp, kipia-aes)
#   эксперт         natalya.expert@example.com       Наталья Орлова    (kipia-aes)
#
#   участник        ivan.petrov@example.com          Иван Петров
#   участник        aleksey.smirnov@example.com      Алексей Смирнов
#   участник        maria.kuznetsova@example.com     Мария Кузнецова
#   участник        pavel.novikov@example.com        Павел Новиков
#   участник        egor.vasilev@example.com         Егор Васильев
#
#   заблокирован    spammer@example.com              Аноним Рекламный
# ─────────────────────────────────────────────────────────────────────────────

# Curriculum lives as a YAML/Markdown tree under db/seeds/curriculum and is
# imported create-only: the DB is the source of truth, so re-seeding never
# overwrites lessons/paths an expert has edited. See CurriculumImporter.
CurriculumImporter.run

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

  # Richer, production-like demo cohort (members/experts/admins + activity,
  # journals, feedback and community edits). Idempotent; development-only.
  load Rails.root.join("db/seeds/development_demo.rb")
end
