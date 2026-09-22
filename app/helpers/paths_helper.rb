module PathsHelper
  def landing_line(text)
    markdown(text).to_str.sub(%r{\A\s*<p>(.*)</p>\s*\z}m, '\1').html_safe
  end

  def hub_facts(path)
    kinds = path.lessons.group(:kind).count
    facts = [ t("common.course", count: path.courses.published.count),
              t("courses.lessons_count", count: kinds["lesson"].to_i) ]
    facts << t("projects.tasks", count: kinds["practice"]) if kinds["practice"].to_i.positive?
    safe_join(facts, " · ")
  end

  # Arc geometry for an inline SVG gauge; the needle angle rides out as a CSS variable.
  MATURITY_GAUGE = { span: 80.0, ticks: 13, cx: 186.0, cy: 290.0, outer: 264.0, inner: 238.0 }.freeze
  # Cells lit per stage — a needle position, not a score.
  MATURITY_FILL = { 1 => 2, 2 => 5, 3 => 9, 4 => 13 }.freeze

  def maturity_needle_angle(stage)
    gauge = MATURITY_GAUGE
    (-gauge[:span] / 2 + gauge[:span] * MATURITY_FILL.fetch(stage) / gauge[:ticks]).round(1)
  end

  def maturity_track_path
    maturity_annulus(-MATURITY_GAUGE[:span] / 2, MATURITY_GAUGE[:span] / 2)
  end

  def maturity_fill_path(stage)
    maturity_annulus(-MATURITY_GAUGE[:span] / 2, maturity_needle_angle(stage))
  end

  def maturity_ticks
    gauge = MATURITY_GAUGE
    step = gauge[:span] / gauge[:ticks]
    (1...gauge[:ticks]).map do |index|
      angle = -gauge[:span] / 2 + step * index
      [ *maturity_point(angle, gauge[:inner]), *maturity_point(angle, gauge[:outer]) ]
    end
  end

  private
    def maturity_annulus(from_deg, to_deg)
      gauge = MATURITY_GAUGE
      x0o, y0o = maturity_point(from_deg, gauge[:outer])
      x1o, y1o = maturity_point(to_deg,   gauge[:outer])
      x1i, y1i = maturity_point(to_deg,   gauge[:inner])
      x0i, y0i = maturity_point(from_deg, gauge[:inner])
      format("M %.2f %.2f A %d %d 0 0 1 %.2f %.2f L %.2f %.2f A %d %d 0 0 0 %.2f %.2f Z",
             x0o, y0o, gauge[:outer], gauge[:outer], x1o, y1o,
             x1i, y1i, gauge[:inner], gauge[:inner], x0i, y0i)
    end

    # Measured from 12 o'clock, positive clockwise — same convention as the needle's CSS rotate().
    def maturity_point(deg, radius)
      gauge = MATURITY_GAUGE
      rad = deg * Math::PI / 180
      [ (gauge[:cx] + radius * Math.sin(rad)).round(2), (gauge[:cy] - radius * Math.cos(rad)).round(2) ]
    end
end
