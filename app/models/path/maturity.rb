module Path::Maturity
  extend ActiveSupport::Concern

  MATURITY_STAGES = 4

  # Stage 4 is maintained, not won once — an expired mark falls back to stage 3.
  VERIFICATION_TTL = 12.months

  included do
    belongs_to :verified_by, class_name: "User", optional: true

    scope :verification_expired, -> { where(verified_at: ..VERIFICATION_TTL.ago) }
  end

  def maturity_stage
    [ true, community_improved?, curated?, verified? ].take_while(&:itself).size
  end

  def verifiable? = maturity_stage >= 3

  # No administrator bypass — even an admin confirms only maps they hold an editorship on.
  def verifiable_by?(user) = user.present? && user.editorships.exists?(path_id: id)

  def verified? = verified_at.present? && verified_at > VERIFICATION_TTL.ago

  def verification_expired? = verified_at.present? && !verified?

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
