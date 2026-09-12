# Everyone whose proposed edit or source was accepted into one profession — the
# object the hub reads instead of asking the Path five different questions.
# Names, not scores: attribution is the one recognition mechanic here (no
# leaderboard, by decision). Members are counted by account, guests by the name
# they signed with; every query is DISTINCT so cost follows people, not
# accepted rows, and each is made once per object.
class Path::Contributors
  # How many people «Кто стоит за картой» names before it stops listing them
  # and says how many more there are.
  SHOWN = 20

  attr_reader :path

  def initialize(path)
    @path = path
  end

  def any? = count.positive?

  def count = user_ids.size + guest_names.size

  # The header's row of faces — photos ride along in one query.
  def faces(limit: 3) = users(limit)

  # The popover's window: members first (they have faces and profiles), guests
  # fill the rest of it, and whatever is left over is one honest line.
  def members = @members ||= users(SHOWN).to_a

  def guests = @guests ||= guest_names.first(SHOWN - members.size)

  def more = count - members.size - guests.size

  private
    def users(limit)
      User.where(id: user_ids).includes(photo_attachment: :blob).order(:name).limit(limit)
    end

    def user_ids
      @user_ids ||= accepted.flat_map { |scope| scope.where.not(user_id: nil).distinct.pluck(:user_id) }.uniq
    end

    def guest_names
      @guest_names ||= accepted.flat_map { |scope| scope.where(user_id: nil).distinct.pluck(:author_name) }.compact_blank.uniq
    end

    def accepted
      [ LessonSuggestion, ResourceSuggestion ].map { |model| model.approved.joins(:lesson).where(lessons: { path_id: path.id }) }
    end
end
