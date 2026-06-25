class JournalEntry < ApplicationRecord
  # Text-only by design: no user uploads on a one-server SQLite app, where a full
  # disk takes down the whole site. The journal is a private practice log; if a
  # public, moderated portfolio ever ships (v0.3), media gets added there fresh —
  # off-disk (object storage), not bolted back onto this private model.
  belongs_to :user
  belongs_to :lesson, optional: true

  has_rich_text :body

  validates :body, presence: true

  scope :ordered, -> { order(created_at: :desc) }
end
