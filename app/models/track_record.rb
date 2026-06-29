# The trust a person has earned, computed live from the append-only logs —
# never stored, never settable. The only inputs are a contributor's own
# suggestions and an editor's approve/reject decisions (themselves logged in
# AdminAction), so the number can't be hand-tuned in anyone's favour, the
# founder's included.
#
# This is an INTERNAL signal — it gates trust (earned editorship) and informs
# moderation review. It is NOT a public leaderboard: recognition lives in
# contributor attribution, competition is deliberately absent (see CLAUDE.md).
#
# Pass a path to slice the record to one profession — the grain Editorship
# works at, so trust in «Электрик» never leaks into «Сварщик».
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

  # Share of decided edits that were accepted — nil until something's been
  # decided, so callers can tell "no track record yet" from "a bad one".
  def acceptance_rate
    decided.zero? ? nil : accepted.to_f / decided
  end

  # The tier the SYSTEM assigns. No human types this in; it moves only as
  # logged decisions accrue.
  def standing
    return :newcomer if accepted < TRUSTED_AT
    return :expert   if accepted >= EXPERT_AT && (acceptance_rate || 0) >= HEALTHY_RATE
    :trusted
  end

  # Professions this person has actually moved (≥1 accepted edit), in catalog
  # order — the basis for proposing an earned editorship.
  def professions_touched
    Path.where(id: @suggestions.approved.joins(:lesson).select("lessons.path_id")).ordered
  end

  # Accepted edits per profession, in catalog order — the per-path trust an
  # earned editorship would be granted against. Returns [[Path, count], ...].
  def accepted_by_profession
    counts = @suggestions.approved.joins(:lesson).group("lessons.path_id").count
    Path.where(id: counts.keys).ordered.map { |path| [ path, counts[path.id] ] }
  end
end
