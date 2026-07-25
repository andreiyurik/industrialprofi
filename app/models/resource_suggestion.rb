# A reader-proposed source for a lesson: the community half of the links story.
# Where a text edit rides LessonSuggestion (a proposed replacement for a body/
# task/description section), a link is structured — url + title + type — so it
# gets its own model and moderation path. An editor of the profession reviews it;
# approving creates the actual Resource on the lesson (origin "human"). Same trust
# ladder as text suggestions: readers propose, experts vet.
class ResourceSuggestion < ApplicationRecord
  # Status lifecycle + close-the-loop machinery (shared with LessonSuggestion).
  include SuggestionModeration

  belongs_to :lesson

  KINDS = Resource::KINDS

  validates :title, presence: true
  # Unlike Resource, a suggested source without a URL is pointless — require one.
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }
  validates :kind, inclusion: { in: KINDS }
  validates :note, length: { maximum: 200 }, allow_blank: true

  # Turn an approved suggestion into a real, editor-owned Resource at the end of
  # the lesson's list, crediting the contributor (durable, mirroring a revision's
  # editor_name). required: false — a reader source is enrichment, not the spine;
  # an editor can promote it later.
  def into_resource!
    lesson.resources.create!(
      title: title, url: url, kind: kind, note: note.presence,
      required: false, origin: "human",
      contributor_name: author_name, contributor: user,
      position: (lesson.resources.maximum(:position) || 0) + 1
    )
  end
end
