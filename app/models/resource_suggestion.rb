# A reader-proposed source for a lesson: the community half of the links story.
# Where a text edit rides LessonSuggestion (a proposed replacement for a body/
# task/description section), a link is structured — url + title + type — so it
# gets its own model and moderation path. An editor of the profession reviews it;
# approving creates the actual Resource on the lesson (origin "human"). Same trust
# ladder as text suggestions: readers propose, experts vet.
class ResourceSuggestion < ApplicationRecord
  belongs_to :lesson
  # Optional: the suggestion outlives the account (matches LessonSuggestion).
  belongs_to :user, optional: true

  KINDS = Resource::KINDS

  validates :author_name, presence: true
  validates :title, presence: true
  # Unlike Resource, a suggested source without a URL is pointless — require one.
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }
  validates :kind, inclusion: { in: KINDS }
  validates :note, length: { maximum: 200 }, allow_blank: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending,  -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }

  def pending?  = status == "pending"
  def approved? = status == "approved"
  def rejected? = status == "rejected"

  # Turn an approved suggestion into a real, editor-owned Resource at the end of
  # the lesson's list. required: false — a reader source is enrichment, not the
  # spine; an editor can promote it later.
  def into_resource!
    lesson.resources.create!(
      title: title, url: url, kind: kind, note: note.presence,
      required: false, origin: "human",
      position: (lesson.resources.maximum(:position) || 0) + 1
    )
  end
end
