# «Взять карту»: a learner keeps someone's map on their dashboard. One row per
# (learner, map); the author can't take their own.
class MapFollow < ApplicationRecord
  belongs_to :map, counter_cache: :follows_count
  belongs_to :user

  validates :user_id, uniqueness: { scope: :map_id }
  validate :not_own_map

  private
    def not_own_map
      errors.add(:map, :invalid) if map && map.user_id == user_id
    end
end
