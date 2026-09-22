# Computed live from the logs, never stored — can't be hand-tuned in anyone's favour.
class TrackRecord
  TRUSTED_AT = 3   # accepted edits before a contributor stops being a newcomer
  EXPERT_AT  = 15  # accepted edits that, with a healthy rate, earn expert standing
  HEALTHY_RATE = 0.6

  def self.for(user, path: nil) = new(user, path:)

  def initialize(user, path: nil)
    @user = user
    @suggestions = user.lesson_suggestions
    @suggestions = @suggestions.joins(:lesson).where(lessons: { path_id: path }) if path
  end

  def submitted = @suggestions.count
  def accepted  = @suggestions.approved.count
  def rejected  = @suggestions.rejected.count
  def decided   = accepted + rejected

  # nil until something's decided, so callers can tell "no track record yet" from "a bad one".
  def acceptance_rate
    decided.zero? ? nil : accepted.to_f / decided
  end

  def standing
    return :newcomer if accepted < TRUSTED_AT
    return :expert   if accepted >= EXPERT_AT && (acceptance_rate || 0) >= HEALTHY_RATE
    :trusted
  end

  def professions_touched
    Path.where(id: @suggestions.approved.joins(:lesson).select("lessons.path_id")).ordered
  end

  def accepted_by_profession
    counts = @suggestions.approved.joins(:lesson).group("lessons.path_id").count
    Path.where(id: counts.keys).ordered.map { |path| [ path, counts[path.id] ] }
  end

  Candidate = Data.define(:user, :path, :accepted)

  # The threshold only proposes a candidate — a human still decides the grant.
  def self.editorship_candidates
    counts = LessonSuggestion.approved
      .joins(:lesson, :user)
      .merge(User.active.where.not(role: :administrator))
      .group(:user_id, "lessons.path_id")
      .having("COUNT(*) >= ?", TRUSTED_AT)
      .count
    granted = Editorship.where(user_id: counts.keys.map(&:first)).pluck(:user_id, :path_id).to_set
    users = User.where(id: counts.keys.map(&:first)).index_by(&:id)
    paths = Path.where(id: counts.keys.map(&:last)).index_by(&:id)

    counts.filter_map { |(user_id, path_id), accepted|
      Candidate.new(user: users[user_id], path: paths[path_id], accepted:) unless granted.include?([ user_id, path_id ])
    }.sort_by { |candidate| -candidate.accepted }
  end
end
