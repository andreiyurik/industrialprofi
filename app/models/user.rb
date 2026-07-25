class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :lesson_completions, dependent: :destroy
  has_many :completed_lessons, through: :lesson_completions, source: :lesson
  has_many :lesson_bookmarks, dependent: :destroy
  has_many :bookmarked_lessons, through: :lesson_bookmarks, source: :lesson
  has_many :journal_entries, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :reactions, dependent: :destroy
  # Per-profession edit grants (see Editorship). Admins edit all and need none.
  has_many :editorships, dependent: :destroy
  has_many :editable_paths, through: :editorships, source: :path
  # Edits this person proposed — the raw material of their track record. Nullify
  # on delete keeps the suggestion and its denormalized author_name, so the
  # immutable revision trail stays intact (history kept, like suspension).
  has_many :lesson_suggestions, dependent: :nullify
  # Sources this person proposed. Nullify on delete, like lesson_suggestions —
  # the suggestion keeps its denormalized author_name.
  has_many :resource_suggestions, dependent: :nullify

  # The trust ladder: member → editor («Эксперт» — reviews suggestions, edits
  # content) → administrator (everything, incl. users and roles).
  enum :role, { member: "member", editor: "editor", administrator: "administrator" }, default: "member"

  # Suspension is a reversible ban: active users can sign in, suspended ones
  # can't. `active` is the scope login authenticates through (Writebook pattern).
  scope :active, -> { where(suspended_at: nil) }
  scope :suspended, -> { where.not(suspended_at: nil) }

  normalizes :email_address, with: ->(email) { email.strip.downcase }
  # The learner's own "why" — shown on the dashboard on every visit (TOP's
  # "learning goal"). Blank saves as nil so presence checks stay simple.
  normalizes :learning_goal, with: ->(goal) { goal.strip.presence }

  # A curator's short public credentials line ("Инженер АСУ ТП, 10 лет, НАКС"),
  # shown next to their name on professions they maintain when they opt in.
  normalizes :headline, with: ->(line) { line.strip.presence }

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
  validates :headline, length: { maximum: 120 }

  def first_name = name.split.first

  def can_administer? = administrator?

  def can_edit_content? = editor? || administrator?

  # The founder's one-shot letter to a freshly promoted editor — pending until
  # explicitly acknowledged (EditorWelcomesController), so it can't be lost to
  # a missed email. Administrators are never greeted this way.
  def needs_editor_welcome? = editor? && editor_welcomed_at.nil?

  def suspended? = suspended_at.present?

  # Ban this account: revoke every session (forces sign-out everywhere) and
  # block future logins. Reversible — history and email are kept intact.
  def suspend!
    transaction do
      sessions.delete_all
      update!(suspended_at: Time.current)
    end
  end

  def reinstate!
    update!(suspended_at: nil)
  end

  # Direct edit rights for ONE profession. Admins edit everything; editors only
  # the professions granted to them (cross-profession edits go through the
  # suggest → review pipeline). The gate for every admin content action.
  # A grant counts only while the role backs it — a demoted editor's leftover
  # rows go dormant, they don't leak access.
  def can_edit_path?(path) = administrator? || (editor? && editorships.exists?(path_id: path&.id))

  # A first editorship grant carries the role with it: a member handed a
  # profession becomes an editor in the same transaction, so role and access
  # can't drift apart. Revoking access never demotes — that stays a human call.
  # Call after the Editorship row(s) exist; returns whether it promoted.
  def promote_to_editor_if_granted!
    return false unless member? && editorships.exists?
    update!(role: :editor)
    true
  end

  # The handshake letter — only for newly granted professions, never on
  # revoke. Called after the granting transaction commits.
  def notify_editorship_grant(paths)
    paths = paths.to_a
    EditorshipsMailer.granted(self, paths).deliver_later if paths.any?
  end

  # Suggestions this user may moderate: all for admins, only their granted
  # professions for editors. Backs the admin queue, its nav badge, and the
  # review digest email.
  def reviewable_suggestions
    return LessonSuggestion.all if administrator?
    return LessonSuggestion.none unless editor?

    LessonSuggestion.joins(:lesson).where(lessons: { path_id: editorships.select(:path_id) })
  end

  # Proposed sources this user may moderate — same profession scoping as
  # reviewable_suggestions, for the resource-suggestion queue and its nav badge.
  def reviewable_resource_suggestions
    return ResourceSuggestion.all if administrator?
    return ResourceSuggestion.none unless editor?

    ResourceSuggestion.joins(:lesson).where(lessons: { path_id: editorships.select(:path_id) })
  end

  def completed?(lesson)
    lesson_completions.exists?(lesson: lesson)
  end

  # One lesson_id Set per path — the unit every progress bar is computed from.
  def completed_lesson_ids_for(path)
    completed_lesson_ids_where(path_id: path.id)
  end

  # Same, scoped to a single course — drives course-level progress bars.
  def completed_lesson_ids_for_course(course)
    completed_lesson_ids_where(course_id: course.id)
  end

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

  # ── Suggestion feedback loop (in-app first, email only as the unread fallback) ──
  # A review queue counts as stalled when its oldest pending edit waited this long.
  SUGGESTION_DIGEST_AFTER = 48.hours

  # Decisions on this user's contributions — proposed edits AND proposed sources
  # — they haven't seen yet. Drives the quiet dot in the header and the touch
  # that closes the loop on the dashboard.
  def unseen_suggestion_outcomes?
    [ lesson_suggestions, resource_suggestions ].any? { |relation| unseen_decisions?(relation) }
  end

  # ONE digest per review stall, never a drip: eligible only when the user
  # opted in, their queue holds an edit that waited SUGGESTION_DIGEST_AFTER,
  # and they weren't already digested since that edit arrived. Clearing the
  # queue resets the cycle.
  def needs_suggestion_digest?
    return false unless suggestion_emails?
    oldest = reviewable_suggestions.pending.minimum(:created_at)
    return false if oldest.nil? || oldest > SUGGESTION_DIGEST_AFTER.ago
    suggestion_digest_sent_at.nil? || suggestion_digest_sent_at < oldest
  end

  # Activity per calendar day (lesson completions + journal entries + suggested
  # edits) — feeds the dashboard heatmap. Counts real work, not logins; a
  # suggestion counts when submitted, not when approved — the effort is the
  # learner's either way. Grouped by LOCAL date: SQLite's DATE() works on the
  # UTC-stored timestamp, so grouping in SQL would bucket late-evening activity
  # into the previous day (the heatmap lost "today" between 00:00–03:00 MSK).
  # We pluck and group in the app zone instead — a learner's rows in the window
  # are few, so this stays cheap.
  def activity_by_day(since:)
    cutoff = since.to_date.beginning_of_day
    [ lesson_completions, journal_entries, lesson_suggestions ].flat_map { |scope|
      scope.where(created_at: cutoff..).pluck(:created_at)
    }.group_by { |timestamp| timestamp.in_time_zone.to_date }
     .transform_values(&:size)
  end

  # How many distinct users did real work (a completion or a journal entry)
  # since `time` — the admin dashboard's "active users" tile. Same "active"
  # definition as #last_active_at, just counted across everyone at once.
  def self.active_count_since(time)
    (LessonCompletion.where(created_at: time..).distinct.pluck(:user_id) |
      JournalEntry.where(created_at: time..).distinct.pluck(:user_id)).size
  end

  private
    def completed_lesson_ids_where(condition)
      lesson_completions.joins(:lesson).where(lessons: condition).pluck(:lesson_id).to_set
    end

    # Any decided contribution in `relation` the user hasn't seen since — shared
    # by the header dot across both suggestion kinds.
    def unseen_decisions?(relation)
      scope = relation.decided.where.not(reviewed_at: nil)
      scope = scope.where("reviewed_at > ?", suggestions_seen_at) if suggestions_seen_at
      scope.exists?
    end
end
