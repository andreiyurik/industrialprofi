module ApplicationHelper
  include Heroicon::Engine.helpers

  # Profession icons: self-hosted Tabler (https://tabler.io/icons) line glyphs,
  # rendered inline so they inherit `currentColor` and the monochrome theme.
  # Each token maps to a partial in app/views/shared/icons/.
  TOPIC_ICONS = %w[bolt helmet droplet cpu tool
                   shield_bolt tools gauge adjustments network device_analytics clipboard_check].freeze

  def topic_icon_svg(token)
    token = "tool" unless TOPIC_ICONS.include?(token)
    render "shared/icons/#{token}"
  end

  PATH_ICON_TOKENS = {
    "elektrik" => "bolt",        # lightning
    "svarshchik" => "helmet",    # welding mask / PPE
    "inzhener-asu-tp" => "cpu",   # controllers / PLC
    "kipia-aes" => "gauge",       # instrumentation / КИП gauge
    "setevoy-inzhener" => "network",        # industrial / OT networks
    "bezopasnost-asu-tp" => "shield_bolt",  # ICS / OT security
    "sysadmin-linux" => "terminal"          # Linux CLI / servers
  }.freeze

  def path_icon_token(path)
    PATH_ICON_TOKENS.fetch(path.slug, "tool")
  end

  # Per-course topic icons (Tabler, same line style as the path set).
  # A course without its own icon falls back to its profession's.
  COURSE_ICON_TOKENS = {
    "elektrik-osnovy-i-bezopasnost" => "shield_bolt",
    "elektrik-montazh-i-ekspluataciya" => "tools",
    "asutp-osnovy-i-kipia" => "gauge",
    "asutp-plk-i-regulirovanie" => "adjustments",
    "asutp-promyshlennye-seti" => "network",
    "asutp-scada" => "device_analytics",
    "asutp-proektirovanie-pnr" => "clipboard_check"
  }.freeze

  def course_icon_token(course)
    COURSE_ICON_TOKENS.fetch(course.slug) { path_icon_token(course.path) }
  end

  # div/span + class survive sanitization so rouge's highlighted output
  # (<div class="highlight"><pre><code><span class="k">…) keeps its token
  # classes. Worst case a class smuggles a cosmetic style — content is
  # admin-curated and suggestions are reviewed, so that's acceptable.
  MARKDOWN_TAGS = %w[h1 h2 h3 h4 h5 h6 p ul ol li a strong em code pre kbd blockquote table thead tbody tr th td hr br img div span].freeze
  MARKDOWN_ATTRS = %w[href src alt target rel class].freeze

  # Attention blocks (GitHub-style admonitions). Authors write `> [!ВАЖНО] …` in
  # plain markdown; we turn the blockquote into a coloured callout with a label.
  # One mechanism, a small fixed set of meanings — accent only where it matters.
  CALLOUTS = {
    "ОПАСНО"  => { mod: "danger",    icon: "exclamation-triangle", label: "Опасно" },
    "ВАЖНО"   => { mod: "important", icon: "information-circle",    label: "Важно" },
    "СОВЕТ"   => { mod: "tip",       icon: "light-bulb",           label: "Совет" },
    "ПРИМЕР"  => { mod: "example",   icon: "calculator",           label: "Разобранный пример" },
    "ПРОВЕРЬ" => { mod: "check",     icon: "check-circle",         label: "Проверь себя" }
  }.freeze

  # Kramdown's default rouge formatter (HTMLLegacy) is deprecated and warns on
  # every render. Same <pre class="highlight"><code> block wrapper, no warning;
  # kramdown's span mode passes wrap: false and gets bare token spans.
  class RougeFormatter < ::Rouge::Formatters::HTML
    def initialize(opts = {})
      super
      @wrap = opts.fetch(:wrap, true)
    end

    def stream(tokens, &block)
      yield %(<pre class="highlight"><code>) if @wrap
      super
      yield "</code></pre>" if @wrap
    end
  end

  def markdown(text, anchor_headings: false)
    return "" if text.blank?
    html = Kramdown::Document.new(text, input: "GFM",
      syntax_highlighter: "rouge",
      syntax_highlighter_opts: { formatter: RougeFormatter }).to_html
    html = sanitize(html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRS)
    # Post-sanitize enrichments — our own markup, so the sanitizer needs no <div>
    # allowance: typed callouts first, then wrap tables for horizontal scroll.
    html = render_callouts(html)
    html = wrap_prose_tables(html)
    html = wrap_code_blocks(html)
    html = wrap_figures(html)
    html = anchor_prose_headings(html) if anchor_headings
    html.html_safe
  end

  # IDs for the in-body ## headings so the lesson TOC can deep-link them.
  # Runs AFTER sanitization (it's our own markup). Anchors are transliterated
  # to ASCII like every slug on the site — Cyrillic fragments break Turbo's
  # scroll-to-anchor (it looks the element up by the percent-encoded hash)
  # and turn copied URLs into percent-soup.
  RU_TRANSLIT = {
    "а" => "a", "б" => "b", "в" => "v", "г" => "g", "д" => "d", "е" => "e",
    "ё" => "e", "ж" => "zh", "з" => "z", "и" => "i", "й" => "y", "к" => "k",
    "л" => "l", "м" => "m", "н" => "n", "о" => "o", "п" => "p", "р" => "r",
    "с" => "s", "т" => "t", "у" => "u", "ф" => "f", "х" => "h", "ц" => "c",
    "ч" => "ch", "ш" => "sh", "щ" => "shch", "ъ" => "", "ы" => "y", "ь" => "",
    "э" => "e", "ю" => "yu", "я" => "ya"
  }.freeze

  def heading_anchor(text)
    slug = text.downcase.gsub(/[а-яё]/) { RU_TRANSLIT[it] }
               .gsub(/[^a-z0-9]+/, "-").delete_prefix("-").delete_suffix("-")
    slug.empty? ? "section" : slug
  end

  def anchor_prose_headings(html)
    doc = Nokogiri::HTML5.fragment(html)
    used = Hash.new(0)
    doc.css("h2").each do |heading|
      base = heading_anchor(heading.text)
      count = (used[base] += 1)
      heading["id"] = count > 1 ? "#{base}-#{count}" : base
    end
    doc.to_html
  end

  def render_callouts(html)
    html.gsub(%r{<blockquote>(.*?)</blockquote>}m) do
      inner = Regexp.last_match(1)
      type = inner[/\[!([А-ЯЁ]+)\]/, 1]
      cfg = type && CALLOUTS[type]
      next "<blockquote>#{inner}</blockquote>" unless cfg

      # Strip the marker AND the hard line break GFM inserts after it (`[!ТИП]`
      # and the body sit on two `>` lines, which kramdown joins with a leading
      # <br> — left in, it renders as a blank first line / extra gap).
      body = inner.sub(%r{\[!#{type}\]\s*(?:<br\s*/?>\s*)?}, "").gsub(%r{<p>\s*</p>}, "")
      label = %(<p class="callout__label">#{heroicon(cfg[:icon], variant: :outline)}<span>#{cfg[:label]}</span></p>)
      %(<div class="callout callout--#{cfg[:mod]}">#{label}#{body}</div>)
    end
  end

  def wrap_prose_tables(html)
    html.gsub("<table>", '<div class="prose-table"><table>')
        .gsub("</table>", "</table></div>")
  end

  # A standalone image — plus its `*Рис. N…*` caption — becomes a single <figure>,
  # so the caption sits tight under the image (small, muted) and the whole thing is
  # one lightbox click target. The caption may sit in the SAME paragraph (next line,
  # no blank — how lessons are authored, so kramdown joins them with a <br>) or in
  # its own following <em> paragraph. Runs post-sanitize (our own markup).
  def wrap_figures(html)
    html.gsub(%r{<p>(<img\b[^>]*?>)\s*(?:<br\s*/?>\s*)?(?:<em>(.*?)</em>)?</p>(?:\s*<p><em>(.*?)</em></p>)?}m) do
      image = Regexp.last_match(1)
      caption = Regexp.last_match(2).presence || Regexp.last_match(3)
      figure = +%(<figure class="prose-figure">#{image})
      figure << %(<figcaption class="prose-figure__caption">#{caption}</figcaption>) if caption.present?
      figure << "</figure>"
      figure
    end
  end

  # Wrap each fenced code block in a copy-button affordance. Runs post-sanitize
  # (our own markup), like the callouts/tables above — so the data-* hooks and
  # the button survive. The button ships `hidden`; the copy-code Stimulus
  # controller reveals it, so there's no dead button without JS.
  def wrap_code_blocks(html)
    button =
      %(<button type="button" class="code-copy" hidden ) +
      %(data-copy-code-target="button" data-action="copy-code#copy" ) +
      %(aria-label="Копировать код" title="Копировать код">) +
      %(<span class="code-copy__icon code-copy__icon--copy">#{heroicon("document-duplicate", variant: :outline)}</span>) +
      %(<span class="code-copy__icon code-copy__icon--done">#{heroicon("check", variant: :outline)}</span>) +
      %(</button>)

    # Matches both highlighted (`<pre class="highlight">`) and plain `<pre>` code
    # blocks — in prose, every <pre> is a code block.
    html.gsub(%r{<pre[^>]*>.*?</pre>}m) do |pre|
      %(<div class="code-block" data-controller="copy-code">#{pre}#{button}</div>)
    end
  end

  # A remote-image attachment (ActionText) whose URL points at a missing asset —
  # e.g. a "TODO-*.png" placeholder an author left for an illustration not yet
  # drawn — must never 500 the whole lesson. Render a calm placeholder instead.
  def safe_remote_image_tag(remote_image)
    image_tag(remote_image.url, width: remote_image.try(:width), height: remote_image.try(:height),
              loading: "lazy", alt: remote_image.try(:caption).to_s)
  rescue Propshaft::MissingAssetError
    tag.span(t("lessons.image_pending"), class: "attachment__missing")
  end

  def lesson_content(lesson, field)
    rich = lesson.send(:"rich_#{field}")
    return rich if rich.present?

    # Memoized per request: the TOC re-reads the rendered body for its anchors.
    @lesson_markdown ||= {}
    @lesson_markdown[[ lesson.id, field ]] ||=
      markdown(lesson.send(field), anchor_headings: field == :body)
  end

  # Entries for the right-rail "В этом уроке" TOC: the body's ## headings.
  # Markdown lessons only — rich_body carries no anchors, so there the rail
  # degrades to just the fixed section links.
  def lesson_toc(lesson)
    return [] if lesson.rich_body.present? || lesson.body.blank?
    Nokogiri::HTML5.fragment(lesson_content(lesson, :body).to_s).css("h2[id]")
      .map { |heading| { title: heading.text, anchor: heading["id"] } }
  end

  def stage_label(stage)
    return "" if stage.blank?
    t("lessons.stages.#{stage}", default: stage.humanize)
  end

  def russian_pluralize(count, key)
    t("common.#{key}", count: count)
  end

  # Resource-type badge (roadmap.sh-style): a coloured pill with a heroicon and
  # the kind label, shown before each resource link. One hue per kind — the
  # "type" axis. The orthogonal "marker" axis (language, and later partner) is a
  # separate small badge, see resource_lang_badge.
  RESOURCE_KIND_BADGES = {
    "norm" => { modifier: "badge--norm", icon: "document-text", label: "norm" },
    "book" => { modifier: "badge--book", icon: "book-open", label: "book" },
    "doc" => { modifier: "badge--doc", icon: "clipboard-document-list", label: "doc" },
    "course" => { modifier: "badge--course", icon: "academic-cap", label: "course" },
    "video" => { modifier: "badge--video", icon: "video-camera", label: "video" },
    "article" => { modifier: "badge--article", icon: "newspaper", label: "article" },
    "software" => { modifier: "badge--software", icon: "cpu-chip", label: "software" },
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

    # Legacy `document` rows: split to norm/book by sniffing the title.
    if resource.title.to_s.match?(NORMATIVE_TITLE)
      RESOURCE_KIND_BADGES["norm"]
    else
      RESOURCE_KIND_BADGES["book"]
    end
  end

  # The orthogonal source-language marker — a small secondary badge shown only
  # for non-Russian sources (the default market language carries no badge).
  def resource_lang_badge(resource)
    return unless resource.respond_to?(:language) && resource.language.present?

    tag.span(resource.language.upcase, class: "badge badge--lang lesson-resource__lang",
      title: t("lessons.resource_languages.#{resource.language}", default: resource.language.upcase))
  end
end
