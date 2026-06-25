# Development-only demo dataset — paints the app the way it will look in
# production once real people use it: a cohort of members/experts/admins with
# spread-out activity, journals, feedback and community edits (some approved →
# "Статью улучшили" + the admin log, some still in the moderation queue).
#
# Idempotent: users upsert by email; every activity block is guarded so re-running
# `db:seed` never duplicates. Safe to run repeatedly in development only.

return unless Rails.env.development?

# ── Cohort ─────────────────────────────────────────────────────────────────
# All demo accounts share the password "password" so you can sign in as anyone
# and see their exact view (a member's dashboard, an expert's admin, etc.).
PASSWORD = "password".freeze

def upsert_user(name:, email:, role:, joined_days_ago:)
  user = User.find_or_create_by!(email_address: email) do |u|
    u.name = name
    u.role = role
    u.password = PASSWORD
  end
  # Stagger signups across ~12 weeks so the dashboard chart & "recent signups"
  # read like a real, gradually-growing audience.
  user.update_columns(role: role, created_at: joined_days_ago.days.ago) if user.created_at > 1.minute.ago || user.role != role
  user
end

admins = [
  upsert_user(name: "Сергей Ковалёв", email: "sergey.admin@example.com",  role: "administrator", joined_days_ago: 84),
  upsert_user(name: "Ольга Морозова", email: "olga.admin@example.com",    role: "administrator", joined_days_ago: 80)
]

experts = {
  "elektrik"        => upsert_user(name: "Виктор Селезнёв", email: "viktor.expert@example.com",  role: "editor", joined_days_ago: 76),
  "inzhener-asu-tp" => upsert_user(name: "Дмитрий Лагутин", email: "dmitry.expert@example.com",  role: "editor", joined_days_ago: 70),
  "kipia-aes"       => upsert_user(name: "Наталья Орлова",  email: "natalya.expert@example.com", role: "editor", joined_days_ago: 58)
}

# joined/last in days-ago: `last` close to 0 = active this week; large `last` =
# stalled (good for eyeballing the reminder mechanic and the heatmap going cold).
member_specs = [
  { name: "Иван Петров",     email: "ivan.petrov@example.com",     path: "elektrik",        done: 16, joined: 78, last: 1 },
  { name: "Алексей Смирнов", email: "aleksey.smirnov@example.com", path: "elektrik",        done: 6,  joined: 40, last: 2 },
  { name: "Мария Кузнецова", email: "maria.kuznetsova@example.com", path: "inzhener-asu-tp", done: 9,  joined: 55, last: 4 },
  { name: "Павел Новиков",   email: "pavel.novikov@example.com",   path: "kipia-aes",       done: 4,  joined: 26, last: 12 },
  { name: "Егор Васильев",   email: "egor.vasilev@example.com",    path: "elektrik",        done: 2,  joined: 18, last: 16 }
]
members = member_specs.map { |s| s.merge(user: upsert_user(name: s[:name], email: s[:email], role: "member", joined_days_ago: s[:joined])) }

# ── Editorships (who maintains which profession) ─────────────────────────────
experts.each do |slug, expert|
  path = Path.find_by(slug: slug)
  Editorship.find_or_create_by!(user: expert, path: path) if path
end
# Дмитрий ведёт и КИПиА в придачу — показывает мульти-профессионального эксперта.
if (kipia = Path.find_by(slug: "kipia-aes"))
  Editorship.find_or_create_by!(user: experts["inzhener-asu-tp"], path: kipia)
end

# ── Lesson completions — the backbone of every progress bar & the heatmap ────
members.each do |m|
  user = m[:user]
  next if user.lesson_completions.any? # idempotent: leave existing progress alone

  path = Path.find_by(slug: m[:path])
  next unless path
  lessons = path.lessons.ordered.limit(m[:done]).to_a
  count = lessons.size
  lessons.each_with_index do |lesson, i|
    frac = count <= 1 ? 1.0 : i.fdiv(count - 1)
    day = (m[:joined] - (m[:joined] - m[:last]) * frac).round
    user.lesson_completions.create!(lesson: lesson, created_at: day.days.ago + rand(0..9).hours)
  end
end

# Experts learn too — a little progress so they aren't empty profiles.
experts.each_value do |expert|
  next if expert.lesson_completions.any?
  path = Path.published.first
  path&.lessons&.ordered&.limit(3)&.each_with_index do |lesson, i|
    expert.lesson_completions.create!(lesson: lesson, created_at: (30 - i * 8).days.ago)
  end
end

# ── Practice journal — private, text-only work logs ──────────────────────────
JOURNALS = {
  "ivan.petrov@example.com" => [
    { title: "Собрал учебный щиток на 4 модуля", days: 3,
      body: "Поставил вводной автомат, УЗО и две группы. Главное — затянул клеммы моментом, а не «на глаз», потом прозвонил все группы. Сидит плотно." },
    { title: "Прозвонил проводку в гараже", days: 9,
      body: "Нашёл, что розетка у верстака висела на скрутке без клеммника. Переделал на Wago, проверил указателем напряжения отсутствие фазы перед работой." },
    { title: "Разобрался с группами допуска", days: 20,
      body: "Перечитал урок про II группу. Записал себе порядок действий перед допуском к работам — теперь не путаюсь." }
  ],
  "maria.kuznetsova@example.com" => [
    { title: "Прочитала первую схему ФСА", days: 5,
      body: "Сначала пугали обозначения, но по уроку разложила P&ID на контуры. Нашла контур регулирования уровня — позиции совпали с таблицей." },
    { title: "Поставила Modbus Poll", days: 11,
      body: "Опросила учебный датчик по Modbus RTU, прочитала регистр температуры. Разобралась, почему сыпались ошибки — был неверный адрес slave." }
  ],
  "aleksey.smirnov@example.com" => [
    { title: "Первая помощь — отработал на манекене", days: 2,
      body: "Прошёл практику по освобождению от тока и СЛР. Засёк ритм компрессий по метроному — держать 100–120 в минуту реально тяжело." }
  ],
  "pavel.novikov@example.com" => [
    { title: "Калибровка датчика давления", days: 13,
      body: "По методике сверил показания на 0/25/50/75/100%. На середине диапазона ушёл на 0.6% — записал в протокол, надо подстроить." }
  ]
}
JOURNALS.each do |email, entries|
  user = User.find_by(email_address: email)
  next if user.nil? || user.journal_entries.any?
  entries.each do |e|
    lesson = user.completed_lessons.order("lesson_completions.created_at").first
    user.journal_entries.create!(title: e[:title], body: e[:body], lesson: lesson,
      created_at: e[:days].days.ago + rand(0..9).hours)
  end
end

# ── Feedback line — messages to the founder (some unread → nav badge) ─────────
FEEDBACKS = [
  { email: "ivan.petrov@example.com",     days: 1,  read: false, url: "/lessons/04-gruppy-dopuska",
    body: "Спасибо за курс по электрике — наконец-то по-человечески разложено про группы допуска. Прошёл бы быстрее, будь видео к практике." },
  { email: "maria.kuznetsova@example.com", days: 2, read: false, url: "/paths/inzhener-asu-tp",
    body: "А можно добавить отдельный блок по протоколу Profibus? По Modbus всё понятно, а вот дальше провал." },
  { email: "pavel.novikov@example.com",   days: 4,  read: true,  url: nil,
    body: "Нашёл опечатку в уроке про калибровку, отправил правку через «предложить изменение». Как понять, что её приняли?" },
  { email: "aleksey.smirnov@example.com", days: 6,  read: true,  url: nil,
    body: "Хочу стать экспертом по бытовой электрике — у меня 8 лет стажа. Куда писать, чем помочь проекту?" },
  { email: "egor.vasilev@example.com",    days: 10, read: true,  url: "/projects",
    body: "Очень не хватает разбора типовых ошибок новичков. В остальном — лучший бесплатный ресурс, что находил." }
]
FEEDBACKS.each do |f|
  user = User.find_by(email_address: f[:email])
  next if user.nil? || user.feedbacks.any?
  user.feedbacks.create!(body: f[:body], page_url: f[:url],
    read_at: (f[:read] ? (f[:days] - 1).days.ago : nil),
    created_at: f[:days].days.ago + rand(0..9).hours)
end

# ── Community edits — the self-developing-content engine ─────────────────────
# Authors of demo suggestions; their presence is the idempotency marker for this
# whole block (so approved edits don't re-append to lesson bodies on re-seed).
DEMO_CONTRIBUTORS = [
  "Иван Петров", "Мария Кузнецова", "Виктор Селезнёв", "Дмитрий Лагутин",
  "Наталья Орлова", "Роман Гаврилов", "Светлана Белова"
].freeze

def lesson_at(path_slug, position)
  path = Path.find_by(slug: path_slug)
  path&.lessons&.ordered&.offset(position - 1)&.first
end

unless LessonSuggestion.where(author_name: DEMO_CONTRIBUTORS).exists?
  reviewer = ->(slug) { Editorship.joins(:user).find_by(path: Path.find_by(slug: slug))&.user || User.administrator.first }

  # Approved edits → an immutable revision crediting the suggester (shows up as
  # "Статью улучшили") + a suggestion_approved entry in the admin log.
  approved = [
    { path: "elektrik", pos: 2, section: "body", author: "Иван Петров", days: 22,
      reason: "Добавил напоминание про проверку отсутствия напряжения",
      addition: "На практике перед началом работ всегда проверяйте отсутствие напряжения указателем — даже если автомат визуально выключен." },
    { path: "elektrik", pos: 2, section: "body", author: "Виктор Селезнёв", days: 14,
      reason: "Уточнил действующую редакцию ГОСТ",
      addition: "Актуальная редакция — ГОСТ 12.1.038-82 (пороговые значения напряжений прикосновения и токов)." },
    { path: "elektrik", pos: 3, section: "task", author: "Светлана Белова", days: 9,
      reason: "Конкретизировал критерий самопроверки",
      addition: "Критерий: компрессии 100–120 в минуту на глубину 5–6 см — сверяйтесь с метрономом." },
    { path: "inzhener-asu-tp", pos: 1, section: "body", author: "Дмитрий Лагутин", days: 18,
      reason: "Назвал стандартный инструмент",
      addition: "> [!СОВЕТ]\nДля быстрой проверки опроса по Modbus используйте Modbus Poll (или бесплатный qModMaster)." },
    { path: "inzhener-asu-tp", pos: 1, section: "body", author: "Мария Кузнецова", days: 7,
      reason: "Добавила частую ошибку новичков",
      addition: "Частая ошибка: неверный адрес slave-устройства — опрос «молчит», хотя физика в порядке." },
    { path: "kipia-aes", pos: 1, section: "description", author: "Наталья Орлова", days: 6,
      reason: "Сделала описание точнее под поиск",
      addition: "Разбираем, чем занимается специалист КИПиА на АЭС и с чего начать путь." }
  ]
  approved.each do |c|
    lesson = lesson_at(c[:path], c[:pos])
    next unless lesson
    base = lesson.section_html(c[:section])
    sug = lesson.lesson_suggestions.create!(author_name: c[:author], section: c[:section],
      edit_reason: c[:reason], base_content: base, body_markdown: c[:addition], status: "pending")
    lesson.revise!(section: c[:section], html: "#{base}\n<p>#{c[:addition]}</p>",
      editor_name: c[:author], edit_reason: c[:reason], source: "suggestion", suggestion: sug)
    sug.update!(status: "approved")
    AdminAction.create!(actor: reviewer.call(c[:path]), action: "suggestion_approved",
      target: sug, details: { lesson: lesson.title, section: c[:section] }, created_at: c[:days].days.ago)
  end

  # Still-pending edits → populate the moderation queue and the nav badge.
  pending = [
    { path: "elektrik", pos: 5, section: "body", author: "Роман Гаврилов", days: 2,
      reason: "Предлагаю пример расчёта сечения",
      proposal: "Можно добавить пример расчёта сечения кабеля по длительному току для типовой бытовой группы 16 А." },
    { path: "elektrik", pos: 1, section: "description", author: "Иван Петров", days: 3,
      reason: "Чуть живее во вступлении",
      proposal: "Профессия электрика: как войти с нуля, какие нормы читать и что собирать руками на практике." },
    { path: "inzhener-asu-tp", pos: 3, section: "task", author: "Мария Кузнецова", days: 1,
      reason: "Добавить критерий сдачи",
      proposal: "В «Что сдать» стоит явно попросить скриншот опроса регистра из Modbus Poll." },
    { path: "kipia-aes", pos: 2, section: "body", author: "Роман Гаврилов", days: 5,
      reason: "Уточнить про поверку",
      proposal: "Стоит развести понятия калибровки и поверки — новички их постоянно путают." }
  ]
  pending.each do |c|
    lesson = lesson_at(c[:path], c[:pos])
    next unless lesson
    lesson.lesson_suggestions.create!(author_name: c[:author], section: c[:section],
      edit_reason: c[:reason], base_content: lesson.section_html(c[:section]),
      body_markdown: c[:proposal], status: "pending", created_at: c[:days].days.ago)
  end

  # One rejected edit → shows the full review lifecycle in the admin log.
  if (lesson = lesson_at("elektrik", 4))
    sug = lesson.lesson_suggestions.create!(author_name: "Роман Гаврилов", section: "body",
      edit_reason: "Хотел упростить", base_content: lesson.section_html("body"),
      body_markdown: "Предлагаю убрать раздел про СИЗ — он и так очевиден.", status: "pending")
    sug.update!(status: "rejected", reviewer_comment: "СИЗ — обязательная часть, упрощать нельзя.")
    AdminAction.create!(actor: experts["elektrik"], action: "suggestion_rejected",
      target: sug, details: { lesson: lesson.title, section: "body" }, created_at: 8.days.ago)
  end
end

# ── A suspended account — shows moderation (the reversible ban) in action ────
spammer = upsert_user(name: "Аноним Рекламный", email: "spammer@example.com", role: "member", joined_days_ago: 9)
if spammer.feedbacks.none?
  spammer.feedbacks.create!(
    body: "Купите дёшево дипломы и удостоверения НАКС без обучения! Пишите в телеграм @...",
    read_at: 4.days.ago, created_at: 5.days.ago
  )
end
unless spammer.suspended?
  spammer.suspend!
  spammer.update_columns(suspended_at: 4.days.ago)
  AdminAction.create!(actor: admins.last, action: "user_suspended", target: spammer,
    details: { subject: spammer.name }, created_at: 4.days.ago)
end

# ── Admin log — backfill the people/role timeline (our Special:Log) ──────────
if AdminAction.where(action: "user_role_changed").none?
  AdminAction.create!(actor: admins.first, action: "user_role_changed", target: experts["elektrik"],
    details: { subject: experts["elektrik"].name, from: "member", to: "editor" }, created_at: 75.days.ago)
  AdminAction.create!(actor: admins.first, action: "user_access_changed", target: experts["elektrik"],
    details: { subject: experts["elektrik"].name, paths: [ Path.find_by(slug: "elektrik")&.title ].compact }, created_at: 75.days.ago)
  AdminAction.create!(actor: admins.first, action: "user_role_changed", target: experts["inzhener-asu-tp"],
    details: { subject: experts["inzhener-asu-tp"].name, from: "member", to: "editor" }, created_at: 69.days.ago)
  AdminAction.create!(actor: admins.last, action: "user_role_changed", target: experts["kipia-aes"],
    details: { subject: experts["kipia-aes"].name, from: "member", to: "editor" }, created_at: 57.days.ago)
end

puts <<~SUMMARY
  Demo cohort ready (all passwords: "password"):
    admins   : #{admins.map(&:email_address).join(", ")}
    experts  : #{experts.values.map(&:email_address).join(", ")}
    members  : #{members.map { |m| m[:user].email_address }.join(", ")}
    suspended: #{User.suspended.pluck(:email_address).join(", ")}
  Activity   : #{LessonCompletion.count} completions · #{JournalEntry.count} journal entries
  Community  : #{LessonSuggestion.where(status: "approved").count} approved / #{LessonSuggestion.pending.count} pending edits · #{Feedback.unread.count} unread messages
  Admin log  : #{AdminAction.count} entries
SUMMARY
