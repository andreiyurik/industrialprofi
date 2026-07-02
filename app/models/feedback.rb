# A message straight to the founder — the in-app feedback line. Async on
# purpose: no chat, no presence, no expectations of an instant reply. The
# founder reads them in /admin/feedbacks and answers by email. Usually from a
# signed-in learner (the address is known); business inquiries (/business) may
# arrive without a user — their contact is folded into the body.
class Feedback < ApplicationRecord
  belongs_to :user, optional: true

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :newest_first, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
end
