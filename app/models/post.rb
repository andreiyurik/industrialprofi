# A news post — the founder's «проект живёт» channel. Admin-authored, no
# comments (zero moderation by design); readers engage with one ❤️ and a
# Telegram share. Body is Lexxy rich text; the hero image is optional.
class Post < ApplicationRecord
  include Sluggable
  include Reactable

  STATUSES = %w[draft published].freeze

  has_rich_text :rich_body
  has_one_attached :hero_image

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: Path::SLUG_FORMAT }
  validates :status, inclusion: { in: STATUSES }
  validate :acceptable_hero_image

  scope :published, -> { where(status: "published").where.not(published_at: nil) }
  scope :recent, -> { order(published_at: :desc, created_at: :desc) }

  def to_param = slug

  def published? = status == "published" && published_at.present?

  # Chronological neighbors for the article footer nav — replaces a "more
  # posts" rail with a single quiet older/newer pair.
  def older
    self.class.published.where("published_at < ?", published_at).recent.first
  end

  def newer
    self.class.published.where("published_at > ?", published_at).order(published_at: :asc, created_at: :asc).first
  end

  private
    def acceptable_hero_image
      return unless hero_image.attached?
      return if LessonImageUpload.permits?(content_type: hero_image.content_type, byte_size: hero_image.byte_size)
      errors.add(:hero_image, :invalid)
    end
end
