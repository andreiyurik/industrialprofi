# Anything a reader can ❤️ once (currently: news posts). One reaction per
# user, toggled on/off; the count is a counter_cache column on the host so the
# button re-renders without a COUNT(*). Mirrors the LessonCompletion/
# LessonBookmark binary-toggle pattern, made reusable via a polymorphic
# association rather than duplicated per model.
module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, dependent: :destroy
  end

  def reacted_by?(user)
    return false unless user
    reactions.exists?(user_id: user.id)
  end
end
