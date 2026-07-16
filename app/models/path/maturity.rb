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

  def maturity_stage
    return 4 if verified?
    return 3 if curated?
    return 2 if community_improved?
    1
  end

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

  def verify!(user)
    update!(verified_at: Time.current, verified_by: user)
  end

  def unverify!
    update!(verified_at: nil, verified_by: nil)
  end
end
