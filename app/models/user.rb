class User < ApplicationRecord
  include Photo

  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :lesson_completions, dependent: :destroy
  has_many :completed_lessons, through: :lesson_completions, source: :lesson
  has_many :lesson_bookmarks, dependent: :destroy
  has_many :bookmarked_lessons, through: :lesson_bookmarks, source: :lesson
  has_many :journal_entries, dependent: :destroy
  has_one :map, dependent: :destroy
  has_many :map_follows, dependent: :destroy
  has_many :followed_maps, through: :map_follows, source: :map
  has_many :feedbacks, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :editorships, dependent: :destroy
  has_many :editable_paths, through: :editorships, source: :path
  # Nullify keeps the suggestion and its immutable revision trail intact.
  has_many :lesson_suggestions, dependent: :nullify
  has_many :resource_suggestions, dependent: :nullify

  enum :role, { member: "member", editor: "editor", administrator: "administrator" }, default: "member"

  normalizes :email_address, with: ->(email) { email.strip.downcase }
  normalizes :learning_goal, with: ->(goal) { goal.strip.presence }
  normalizes :headline, with: ->(line) { line.strip.presence }
  normalizes :handle, with: ->(handle) { handle.strip.downcase.presence }

  # Token embeds the password salt, so a password change invalidates it.
  generates_token_for :password_reset, expires_in: 1.hour do
    password_salt&.last(10)
  end

  generates_token_for :email_unsubscribe

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :learning_goal, length: { maximum: 200 }
  validates :headline, length: { maximum: 120 }
  validates :handle, uniqueness: true, length: { in: 3..30 }, format: { with: Path::SLUG_FORMAT }, allow_nil: true
  # Handle can't be cleared while a map exists; only checked when handle changed.
  validates :handle, presence: true, if: -> { handle_changed? && map }
  validates :avatar_token, inclusion: { in: Avatar.tokens }, allow_blank: true
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }

  scope :active, -> { where(suspended_at: nil) }
  scope :with_profile, -> { active.where.not(handle: nil) }
  scope :suspended, -> { where.not(suspended_at: nil) }

  def first_name = name.split.first

  def profile? = handle.present? && !suspended?

  def ensure_handle!
    return handle if handle.present?

    base = Path.slugify(name).first(24).delete_suffix("-").presence || "user"
    base = base.ljust(3, "0")
    candidate = base
    suffix = 2
    while User.exists?(handle: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    update!(handle: candidate)
    candidate
  end

  def curated_paths
    can_edit_content? ? editable_paths.published.ordered : Path.none
  end

  def improved_lessons
    ids = lesson_suggestions.approved.select(:lesson_id)
    source_ids = resource_suggestions.approved.select(:lesson_id)
    Lesson.where(id: ids).or(Lesson.where(id: source_ids)).ordered.includes(:path)
  end

  def can_administer? = administrator?

  def can_edit_content? = editor? || administrator?

  def needs_editor_welcome? = editor? && editor_welcomed_at.nil?

  def suspended? = suspended_at.present?

  def suspend!
    transaction do
      sessions.delete_all
      update!(suspended_at: Time.current)
    end
  end

  def reinstate!
    update!(suspended_at: nil)
  end

  def can_edit_path?(path) = administrator? || (editor? && editorships.exists?(path_id: path&.id))

  # Call after the editorship grant exists; revoking access never demotes back.
  def promote_to_editor_if_granted!
    return false unless member? && editorships.exists?
    update!(role: :editor)
    true
  end

  # Only for newly granted professions, never on revoke. Call after the transaction commits.
  def notify_editorship_grant(paths)
    paths = paths.to_a
    EditorshipsMailer.granted(self, paths).deliver_later if paths.any?
  end

  def reviewable_suggestions
    return LessonSuggestion.all if administrator?
    return LessonSuggestion.none unless editor?

    LessonSuggestion.joins(:lesson).where(lessons: { path_id: editorships.select(:path_id) })
  end

  def reviewable_resource_suggestions
    return ResourceSuggestion.all if administrator?
    return ResourceSuggestion.none unless editor?

    ResourceSuggestion.joins(:lesson).where(lessons: { path_id: editorships.select(:path_id) })
  end

  def completed?(lesson)
    lesson_completions.exists?(lesson: lesson)
  end

  def completed_lesson_ids_for(path)
    completed_lesson_ids_where(path_id: path.id)
  end

  def completed_lesson_ids_for_course(course)
    completed_lesson_ids_where(course_id: course.id)
  end

  def completed_lesson_ids = lesson_completions.pluck(:lesson_id).to_set

  def milestone_reached_for(lesson, completed_ids:)
    course = lesson.course
    path = lesson.path
    path_completed_ids = completed_lesson_ids_for(path)

    if path.lessons.all? { |l| path_completed_ids.include?(l.id) }
      :path
    elsif course.lessons.all? { |l| completed_ids.include?(l.id) }
      :course
    elsif lesson.stage.present? && course.lessons.select { |l| l.stage == lesson.stage }.all? { |l| completed_ids.include?(l.id) }
      :stage
    end
  end

  def started_paths
    Path.published.where(id: lesson_completions.joins(:lesson).select("lessons.path_id")).ordered
  end

  # Skips unpublished paths so focus stays in started_paths — a draft won't blank the dashboard.
  def focus_path
    path_id = lesson_completions.joins(lesson: :path).merge(Path.published)
                                .order(created_at: :desc).limit(1).pick("lessons.path_id")
    Path.find_by(id: path_id) if path_id
  end

  def next_lesson_in(path)
    path.lessons.ordered.where.not(id: lesson_completions.select(:lesson_id)).first
  end

  REMINDER_AFTER = 7.days

  def last_active_at
    [ lesson_completions.maximum(:created_at), journal_entries.maximum(:created_at) ].compact.max
  end

  def needs_learning_reminder?
    return false unless reminder_emails?
    last = last_active_at
    return false if last.nil? || last > REMINDER_AFTER.ago
    return false if reminded_at && reminded_at > last
    focus_path.present? && next_lesson_in(focus_path).present?
  end

  SUGGESTION_DIGEST_AFTER = 48.hours

  def unseen_suggestion_outcomes?
    [ lesson_suggestions, resource_suggestions ].any? { |relation| unseen_decisions?(relation) }
  end

  def needs_suggestion_digest?
    return false unless suggestion_emails?
    oldest = reviewable_suggestions.pending.minimum(:created_at)
    return false if oldest.nil? || oldest > SUGGESTION_DIGEST_AFTER.ago
    suggestion_digest_sent_at.nil? || suggestion_digest_sent_at < oldest
  end

  # Grouped in Ruby, not SQL DATE() — that runs on UTC and would misbucket evening activity.
  def activity_by_day(since:)
    cutoff = since.to_date.beginning_of_day
    [ lesson_completions, journal_entries, lesson_suggestions ].flat_map { |scope|
      scope.where(created_at: cutoff..).pluck(:created_at)
    }.group_by { |timestamp| timestamp.in_time_zone.to_date }
     .transform_values(&:size)
  end

  def self.active_count_since(time)
    (LessonCompletion.where(created_at: time..).distinct.pluck(:user_id) |
      JournalEntry.where(created_at: time..).distinct.pluck(:user_id)).size
  end

  def self.filtered(role:, status:, q:)
    scope = order(created_at: :desc)
    scope = scope.where(role: role) if roles.key?(role)
    scope = scope.suspended if status == "suspended"
    if q.present?
      like = "%#{sanitize_sql_like(q.strip)}%"
      scope = scope.where("name LIKE :q OR email_address LIKE :q", q: like)
    end
    scope
  end

  private
    def completed_lesson_ids_where(condition)
      lesson_completions.joins(:lesson).where(lessons: condition).pluck(:lesson_id).to_set
    end

    def unseen_decisions?(relation)
      scope = relation.decided.where.not(reviewed_at: nil)
      scope = scope.where("reviewed_at > ?", suggestions_seen_at) if suggestions_seen_at
      scope.exists?
    end
end
