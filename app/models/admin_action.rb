# Admin actions over PEOPLE and MODERATION (role changes, grants, suggestion
# decisions, rollbacks) — content edits have their own trail in LessonRevision.
# `details` is denormalized so entries stay readable after the actor/target is deleted.
class AdminAction < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :target, polymorphic: true, optional: true

  validates :action, presence: true

  scope :ordered, -> { order(created_at: :desc, id: :desc) }

  def readonly? = persisted?
end
