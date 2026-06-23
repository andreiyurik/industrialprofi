class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :lesson_completions, dependent: :destroy
  has_many :completed_lessons, through: :lesson_completions, source: :lesson
  has_many :lesson_bookmarks, dependent: :destroy
  has_many :bookmarked_lessons, through: :lesson_bookmarks, source: :lesson
  has_many :journal_entries, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  # Per-profession edit grants (see Editorship). Admins edit all and need none.
  has_many :editorships, dependent: :destroy
  has_many :editable_paths, through: :editorships, source: :path

  # The trust ladder: member → editor («Эксперт» — reviews suggestions, edits
  # content) → administrator (everything, incl. users and roles).
  enum :role, { member: "member", editor: "editor", administrator: "administrator" }, default: "member"

  normalizes :email_address, with: ->(email) { email.strip.downcase }
  # The learner's own "why" — shown on the dashboard on every visit (TOP's
  # "learning goal"). Blank saves as nil so presence checks stay simple.
  normalizes :learning_goal, with: ->(goal) { goal.strip.presence }

  # Single-use by construction: the token embeds part of the password salt,
  # so changing the password invalidates every outstanding reset link.
  generates_token_for :password_reset, expires_in: 1.hour do
    password_salt&.last(10)
  end

  # One-click unsubscribe links in reminder emails. No expiry on purpose —
  # an unsubscribe link must keep working however old the email is.
  generates_token_for :email_unsubscribe

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :learning_goal, length: { maximum: 200 }

  def can_administer? = administrator?

  def can_edit_content? = editor? || administrator?

  # Direct edit rights for ONE profession. Admins edit everything; editors only
  # the professions granted to them (cross-profession edits go through the
  # suggest → review pipeline). The gate for every admin content action.
  def can_edit_path?(path) = administrator? || editorships.exists?(path_id: path&.id)

  def completed?(lesson)
    lesson_completions.exists?(lesson: lesson)
  end

  # One lesson_id Set per path — the unit every progress bar is computed from.
  def completed_lesson_ids_for(path)
    lesson_completions.joins(:lesson).where(lessons: { path_id: path.id }).pluck(:lesson_id).to_set
  end

  # Same, scoped to a single course — drives course-level progress bars.
  def completed_lesson_ids_for_course(course)
    lesson_completions.joins(:lesson).where(lessons: { course_id: course.id }).pluck(:lesson_id).to_set
  end

  # Paths the user has at least one completion in, in catalog order.
  def started_paths
    Path.published.where(id: lesson_completions.joins(:lesson).select("lessons.path_id")).ordered
  end

  # The ONE direction the learner is currently working on — the path of their
  # most recent completion. Derived, not stored: switching focus is simply
  # doing a lesson elsewhere, no settings to manage.
  def focus_path
    path_id = lesson_completions.joins(:lesson).order(created_at: :desc).limit(1).pick("lessons.path_id")
    Path.published.find_by(id: path_id) if path_id
  end

  # The first not-yet-completed lesson — where "Continue" should land.
  def next_lesson_in(path)
    path.lessons.ordered.where.not(id: lesson_completions.select(:lesson_id)).first
  end

  # ── Learning reminder (the one retention email) ──
  # A learner counts as stalled after this much silence.
  REMINDER_AFTER = 7.days

  # When the user last did real work (a completion or a journal entry) —
  # logins don't count, same definition as the heatmap.
  def last_active_at
    [ lesson_completions.maximum(:created_at), journal_entries.maximum(:created_at) ].compact.max
  end

  # ONE quiet nudge per stall, never a drip campaign: eligible only when the
  # user opted in, has somewhere to continue, went silent for REMINDER_AFTER,
  # and hasn't already been nudged since their last activity.
  def needs_learning_reminder?
    return false unless reminder_emails?
    last = last_active_at
    return false if last.nil? || last > REMINDER_AFTER.ago
    return false if reminded_at && reminded_at > last
    focus_path.present? && next_lesson_in(focus_path).present?
  end

  # Activity per calendar day (lesson completions + journal entries) — feeds
  # the dashboard heatmap. Counts real work, not logins.
  def activity_by_day(since:)
    [ lesson_completions, journal_entries ].map { |scope|
      scope.where(created_at: since.to_date.beginning_of_day..).group("DATE(created_at)").count
    }.reduce { |a, b| a.merge(b) { |_, x, y| x + y } }
     .transform_keys { |day| Date.parse(day.to_s) }
  end
end
