class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :lesson_completions, dependent: :destroy
  has_many :completed_lessons, through: :lesson_completions, source: :lesson

  enum :role, { member: "member", administrator: "administrator" }, default: "member"

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  # Single-use by construction: the token embeds part of the password salt,
  # so changing the password invalidates every outstanding reset link.
  generates_token_for :password_reset, expires_in: 1.hour do
    password_salt&.last(10)
  end

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def can_administer? = administrator?

  def completed?(lesson)
    lesson_completions.exists?(lesson: lesson)
  end

  # One lesson_id Set per path — the unit every progress bar is computed from.
  def completed_lesson_ids_for(path)
    lesson_completions.joins(:lesson).where(lessons: { path_id: path.id }).pluck(:lesson_id).to_set
  end

  # Paths the user has at least one completion in, in catalog order.
  def started_paths
    Path.published.where(id: lesson_completions.joins(:lesson).select("lessons.path_id")).ordered
  end

  # The first not-yet-completed lesson — where "Continue" should land.
  def next_lesson_in(path)
    path.lessons.ordered.where.not(id: lesson_completions.select(:lesson_id)).first
  end
end
