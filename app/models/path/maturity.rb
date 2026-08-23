# The public maturity ladder of a profession map — four rungs shown as a
# Basecamp-style needle in the path hero. Each rung is a verifiable fact, never
# an activity counter (a farmable metric would invite noise edits, the same
# reason the leaderboard was rejected). Rungs 1–3 derive live from existing
# data; rung 4 is the one a human sets by hand — the curator "moves the needle".
module Path::Maturity
  extend ActiveSupport::Concern

  MATURITY_STAGES = 4

  # The expert mark carries a shelf life: standards move on, so a mark older
  # than this quietly stops counting and the map falls back to stage 3 until
  # the curator re-confirms. Keeps «проверено» meaning "recently true" —
  # stage 4 is maintained, not won once.
  VERIFICATION_TTL = 12.months

  included do
    belongs_to :verified_by, class_name: "User", optional: true

    scope :verification_expired, -> { where(verified_at: ..VERIFICATION_TTL.ago) }
  end

  # A ladder, not a checklist: a rung counts only with every rung below it.
  # An expert's mark on a map with no expert — or no accepted edits — is worth
  # nothing, so it cannot lift the needle; only climbing in order does.
  def maturity_stage
    [ true, community_improved?, curated?, verified? ].take_while(&:itself).size
  end

  # The mark may be set (or refreshed) only once the map is genuinely curated
  # and community-improved — stage 3 reached, or already at 4 and re-confirming.
  def verifiable? = maturity_stage >= 3

  # Only someone who actually curates THIS map vouches for it: a grant on the
  # profession, not a role — an administrator confirms only maps they hold too
  # (and a grant is a logged, visible act).
  def verifiable_by?(user) = user.present? && user.editorships.exists?(path_id: id)

  def verified? = verified_at.present? && verified_at > VERIFICATION_TTL.ago

  def verification_expired? = verified_at.present? && !verified?

  # A practitioner maintains this map: an active editor holds a grant — the
  # same rule as Editorship.count_published_paths_with_editor.
  def curated?
    editorships.joins(:user).merge(User.active.where(role: :editor)).exists?
  end

  def community_improved? = approved_suggestions_count.positive?

  def approved_suggestions_count
    LessonSuggestion.approved.joins(:lesson).where(lessons: { path_id: id }).count
  end

  NotVerifiable = Class.new(StandardError)

  def verify!(user)
    raise NotVerifiable unless verifiable? && verifiable_by?(user)

    update!(verified_at: Time.current, verified_by: user)
  end

  def unverify!
    update!(verified_at: nil, verified_by: nil)
  end
end
