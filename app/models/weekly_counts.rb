# Buckets by LOCAL date, not SQLite's DATE() — that reads UTC and misfiles evening activity.
class WeeklyCounts
  def self.for(scope, weeks:)
    new(scope, weeks).to_a
  end

  def initialize(scope, weeks)
    @scope = scope
    @weeks = weeks
  end

  def to_a
    (0...@weeks).map do |i|
      start = from + (i * 7)
      [ start, (start..start + 6).sum { |day| daily_counts[day].to_i } ]
    end
  end

  private
    def from = (@weeks - 1).weeks.ago.to_date.beginning_of_week

    def daily_counts
      @daily_counts ||= @scope.where(created_at: from.beginning_of_day..)
                               .pluck(:created_at)
                               .group_by { |timestamp| timestamp.in_time_zone.to_date }
                               .transform_values(&:size)
    end
end
