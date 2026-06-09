module ApplicationHelper
  include Heroicon::Engine.helpers

  # Profession icons: self-hosted Tabler (https://tabler.io/icons) line glyphs,
  # rendered inline so they inherit `currentColor` and the monochrome theme.
  # Each token maps to a partial in app/views/shared/icons/.
  TOPIC_ICONS = %w[bolt helmet droplet cpu tool].freeze

  def topic_icon_svg(token)
    token = "tool" unless TOPIC_ICONS.include?(token)
    render "shared/icons/#{token}"
  end

  PATH_ICON_TOKENS = {
    "elektrik" => "bolt",        # lightning
    "svarshchik" => "helmet",    # welding mask / PPE
    "santehnik" => "droplet",    # water / plumbing
    "inzhener-asu-tp" => "cpu"   # controllers / PLC
  }.freeze

  def path_icon_token(path)
    PATH_ICON_TOKENS.fetch(path.slug, "tool")
  end

  MARKDOWN_TAGS = %w[h1 h2 h3 h4 h5 h6 p ul ol li a strong em code pre blockquote table thead tbody tr th td hr br img].freeze
  MARKDOWN_ATTRS = %w[href src alt target rel].freeze

  def markdown(text)
    return "" if text.blank?
    html = Kramdown::Document.new(text, input: "GFM").to_html
    sanitize(html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRS)
  end

  def lesson_content(lesson, field)
    rich_field = :"rich_#{field}"
    if lesson.send(rich_field).present?
      lesson.send(rich_field)
    else
      markdown(lesson.send(field))
    end
  end

  def stage_label(stage)
    return "" if stage.blank?
    t("lessons.stages.#{stage}", default: stage.humanize)
  end

  def russian_pluralize(count, key)
    t("common.#{key}", count: count)
  end

  # Resource-type badge (roadmap.sh-style): a coloured pill with a heroicon and
  # the kind label, shown before each resource link. One hue per kind.
  RESOURCE_KIND_BADGES = {
    "video" => { modifier: "badge--video", icon: "video-camera", label: "video" },
    "article" => { modifier: "badge--article", icon: "newspaper", label: "article" },
    "tool" => { modifier: "badge--tool", icon: "wrench-screwdriver", label: "tool" }
  }.freeze

  # A `document` resource is either an official standard ("Норматив") or a
  # book/handbook ("Книга"). We can't tell from `kind` alone, so we sniff the
  # title: anything starting like a Russian regulation is a norm, else a book.
  NORMATIVE_TITLE = /\A\s*(ГОСТ|ПУЭ|ПТЭЭП|ПТЭ|ПОТ[\s\d]|СП[\s\d]|СНиП|СО[\s\d]|РД[\s\d]|СанПиН|ВСН[\s\d]|ОСТ[\s\d]|Приказ|Федеральн|ФЗ[\s-]|Технический регламент|Правила|Приложение|Инструкция|Типов|Межотраслев|Профессиональн|Профстандарт|ANSI|ASME|EEMUA|ISA[\s-]|IEC[\s\d]|ISO[\s\d]|EN[\s\d]|DIN[\s\d]|API[\s\d]|NFPA|МЭК)/i

  def resource_kind_badge(resource)
    meta = resource_badge_meta(resource)
    label = t("lessons.resource_kinds.#{meta[:label]}", default: meta[:label].to_s.humanize)
    tag.span(class: "badge #{meta[:modifier]} lesson-resource__badge") do
      safe_join([ heroicon(meta[:icon], variant: :outline), tag.span(label) ])
    end
  end

  def resource_badge_meta(resource)
    return RESOURCE_KIND_BADGES[resource.kind] if RESOURCE_KIND_BADGES.key?(resource.kind)

    if resource.title.to_s.match?(NORMATIVE_TITLE)
      { modifier: "badge--norm", icon: "document-text", label: "norm" }
    else
      { modifier: "badge--book", icon: "book-open", label: "book" }
    end
  end
end
