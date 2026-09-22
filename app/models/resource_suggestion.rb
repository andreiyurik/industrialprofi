# Structured link (url+title+type) proposal — the community half of the links story, separate
# from LessonSuggestion's text edits. Approving creates the actual Resource (origin "human").
class ResourceSuggestion < ApplicationRecord
  # Status lifecycle + close-the-loop machinery (shared with LessonSuggestion).
  include SuggestionModeration

  belongs_to :lesson

  KINDS = Resource::KINDS

  validates :title, presence: true
  # Unlike Resource, a suggested source without a URL is pointless — require one.
  validates :url, presence: true, format: { with: URL_FORMAT }
  validates :kind, inclusion: { in: KINDS }
  validates :note, length: { maximum: 200 }, allow_blank: true

  # Credit is durable (mirrors a revision's editor_name); required: false — enrichment,
  # not the spine, though an editor can promote it later.
  def into_resource!
    lesson.resources.create!(
      title: title, url: url, kind: kind, note: note.presence,
      required: false, origin: "human",
      contributor_name: author_name, contributor: user,
      position: (lesson.resources.maximum(:position) || 0) + 1
    )
  end
end
