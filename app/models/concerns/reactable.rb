# One reaction per user, toggled on/off; counter_cache avoids a COUNT(*) on render.
# Mirrors the LessonCompletion/LessonBookmark toggle pattern via a polymorphic association.
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
