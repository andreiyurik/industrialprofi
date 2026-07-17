module PathsHelper
  # Maturity-gauge geometry — Basecamp's Needle, faithfully: a long shallow
  # outlined arc (80° of a large circle) divided into cells, filled up to the
  # needle. Plain trig here means the gauge ships as inline SVG — no images,
  # no JS; the needle angle rides out as a CSS variable.
  MATURITY_GAUGE = { span: 80.0, ticks: 13, cx: 186.0, cy: 290.0, outer: 264.0, inner: 238.0 }.freeze
  # Cells lit per stage — a needle position, not a score.
  MATURITY_FILL = { 1 => 2, 2 => 5, 3 => 9, 4 => 13 }.freeze

  def maturity_needle_angle(stage)
    gauge = MATURITY_GAUGE
    (-gauge[:span] / 2 + gauge[:span] * MATURITY_FILL.fetch(stage) / gauge[:ticks]).round(1)
  end

  # The outlined track: a closed annular band from edge to edge.
  def maturity_track_path
    maturity_annulus(-MATURITY_GAUGE[:span] / 2, MATURITY_GAUGE[:span] / 2)
  end

  # The progress fill: the same band, cut off at the needle.
  def maturity_fill_path(stage)
    maturity_annulus(-MATURITY_GAUGE[:span] / 2, maturity_needle_angle(stage))
  end

  # Cell dividers — [x1, y1, x2, y2] per internal boundary, inner→outer.
  def maturity_ticks
    gauge = MATURITY_GAUGE
    step = gauge[:span] / gauge[:ticks]
    (1...gauge[:ticks]).map do |index|
      angle = -gauge[:span] / 2 + step * index
      [ *maturity_point(angle, gauge[:inner]), *maturity_point(angle, gauge[:outer]) ]
    end
  end

  private
    # Closed band between the outer and inner radii across [from, to] degrees.
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

    # Angle is measured from 12 o'clock, positive clockwise — same convention
    # the needle's CSS rotate() uses.
    def maturity_point(deg, radius)
      gauge = MATURITY_GAUGE
      rad = deg * Math::PI / 180
      [ (gauge[:cx] + radius * Math.sin(rad)).round(2), (gauge[:cy] - radius * Math.cos(rad)).round(2) ]
    end
end
