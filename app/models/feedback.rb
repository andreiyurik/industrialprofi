# A message from a signed-in learner straight to the founder — the in-app
# feedback line. Async on purpose: no chat, no presence, no expectations of an
# instant reply. The founder reads them in /admin/feedbacks and answers by
# email (the sender is a registered user, so the address is known).
class Feedback < ApplicationRecord
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :newest_first, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
end
