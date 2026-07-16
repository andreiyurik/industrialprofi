module PathsHelper
  # Maturity-gauge geometry: a shallow 130° arc of 13 ticks (Basecamp's needle,
  # recolored to our ladder). Plain trig here means the gauge ships as inline
  # SVG — no images, no JS; the needle angle rides out as a CSS variable.
  MATURITY_GAUGE = { span: 130.0, ticks: 13, radius: 86, thickness: 13, gap: 2.2, cx: 100, cy: 104 }.freeze
  # Ticks lit per stage — a needle position, not a score.
  MATURITY_FILL = { 1 => 2, 2 => 5, 3 => 9, 4 => 13 }.freeze

  def maturity_needle_angle(stage)
    gauge = MATURITY_GAUGE
    (-gauge[:span] / 2 + gauge[:span] * MATURITY_FILL.fetch(stage) / gauge[:ticks]).round(1)
  end

  # => [{ d: "M … A …", filled: true }, …] — one arc-stroke path per tick.
  def maturity_gauge_segments(stage)
    gauge = MATURITY_GAUGE
    step = gauge[:span] / gauge[:ticks]
    start = -gauge[:span] / 2
    Array.new(gauge[:ticks]) do |index|
      { d: maturity_arc(start + step * index + gauge[:gap] / 2, start + step * (index + 1) - gauge[:gap] / 2),
        filled: index < MATURITY_FILL.fetch(stage) }
    end
  end

  private
    def maturity_arc(from_deg, to_deg)
      radius = MATURITY_GAUGE[:radius]
      x0, y0 = maturity_point(from_deg)
      x1, y1 = maturity_point(to_deg)
      format("M %.2f %.2f A %d %d 0 0 1 %.2f %.2f", x0, y0, radius, radius, x1, y1)
    end

    # Angle is measured from 12 o'clock, positive clockwise — same convention
    # the needle's CSS rotate() uses.
    def maturity_point(deg)
      gauge = MATURITY_GAUGE
      rad = deg * Math::PI / 180
      [ gauge[:cx] + gauge[:radius] * Math.sin(rad), gauge[:cy] - gauge[:radius] * Math.cos(rad) ]
    end
end
