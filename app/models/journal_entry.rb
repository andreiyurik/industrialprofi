class JournalEntry < ApplicationRecord
  # Text-only by design: no per-user uploads (one full disk takes down a one-server
  # SQLite app). A future public portfolio would need its own model, off-disk.
  belongs_to :user
  belongs_to :lesson, optional: true

  has_rich_text :body

  validates :body, presence: true

  scope :ordered, -> { order(created_at: :desc) }
end
