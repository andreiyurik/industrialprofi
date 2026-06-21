class LessonBookmark < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  validates :lesson_id, uniqueness: { scope: :user_id }
end
