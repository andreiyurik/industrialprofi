# The transparency log — our Special:Log. An append-only record of every
# administrator action over PEOPLE and MODERATION (role changes, profession
# grants, suggestion approve/reject, rollbacks), so delegated power stays
# reviewable as the team grows. Content edits already have their own audit
# trail in LessonRevision; this is the second log, for everything else.
#
# Human-readable facts live denormalized in `details`, so each entry reads
# correctly forever — even if the actor or target is later deleted.
class AdminAction < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :target, polymorphic: true, optional: true

  validates :action, presence: true

  scope :ordered, -> { order(created_at: :desc, id: :desc) }

  # Immutable: an audit entry can be created (and read), never edited.
  def readonly? = persisted?
end
