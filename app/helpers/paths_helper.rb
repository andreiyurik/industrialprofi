module PathsHelper
  def landing_line(text)
    markdown(text).to_str.sub(%r{\A\s*<p>(.*)</p>\s*\z}m, '\1').html_safe
  end

  # «43 статьи» → the number and its noun apart, so the plural rules stay in one key.
  def hub_stat(text)
    number, label = text.split(" ", 2)
    tag.li(class: "hub-stats__item") { tag.strong(number, class: "hub-stats__number") + tag.span(label, class: "hub-stats__label") }
  end

  def hub_tab(name, url, icon:, current:, count: nil)
    link_to url, class: "hub-tabs__link", aria: { current: ("page" if current) } do
      safe_join([ icon_tag(icon), tag.span(name), (tag.span(count, class: "hub-tabs__count") if count.to_i.positive?) ])
    end
  end

  # A highlight written as «**Навык:** пояснение» splits into a tile's title and its small print.
  def landing_tile(text)
    lead, rest = text.to_s.match(/\A\*\*(.+?):?\*\*:?\s*(.*)\z/m)&.captures
    lead ? [ lead, rest.sub(/\A[,—–-]\s*/, "") ] : [ nil, text ]
  end

  def scene_node(node, place, chapters)
    body = safe_join([ tag.span(icon_tag(node.emblem), class: "scene__icon"),
                       tag.strong(node.name, class: "scene__name"),
                       (tag.span(node.does, class: "scene__does") if node.does.present?) ])
    css = "scene__node scene__node--#{place}"
    course = chapters[node.course]
    course ? link_to(body, course_path(course), class: css, title: course.title) : tag.div(body, class: css)
  end

  def scene_wire(area, direction, label = nil)
    tag.span(class: "scene__wire scene__wire--#{direction}", style: "grid-area: #{area}", aria: { hidden: label.blank? || nil }) do
      tag.span(label, class: "scene__label") if label.present?
    end
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
