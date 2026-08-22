module ApplicationHelper
  # A Phosphor glyph painted as a CSS mask (see icons.css) — no SVG reaches the
  # HTML. Size comes from --icon-size on the surrounding context (1em by default);
  # weight is part of the name: `-light` for emblems ≥32px, `-fill` for state.
  def icon_tag(name, **options)
    tag.span class: class_names("icon icon--#{name}", options.delete(:class)), "aria-hidden": true, **options
  end

  # Admin is a focused internal workspace, not a marketing surface — it drops the
  # public footer (its persistent nav covers navigation).
  def in_admin?
    controller.is_a?(Admin::BaseController)
  end

  # Each language names itself in its own tongue (the reader who needs the
  # switcher can't read the current language), clipped to three letters —
  # full names read as a paragraph, not a control.
  # Each language names itself in its own tongue, clipped to a three-letter
  # mark — a control, not a word (founder's call, 2026-08-22); no flags.
  LOCALE_NAMES = { ru: "Рус", en: "Eng" }.freeze

  def native_locale_name(locale)
    LOCALE_NAMES.fetch(locale, locale.to_s)
  end

  # The switcher's target: the same page where it exists in both languages,
  # the other locale's home where the content is locale-bound.
  def locale_switch_url(locale)
    bilingual_page? ? url_for(locale: locale) : root_path(locale: locale)
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
    "ОПАСНО"  => { mod: "danger",    icon: "warning",      label: "Опасно" },
    "ВАЖНО"   => { mod: "important", icon: "info",         label: "Важно" },
    "СОВЕТ"   => { mod: "tip",       icon: "lightbulb",    label: "Совет" },
    "ПРИМЕР"  => { mod: "example",   icon: "calculator",   label: "Разобранный пример" },
    "ПРОВЕРЬ" => { mod: "check",     icon: "check-circle", label: "Проверь себя" }
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
    enrich_prose(html, anchor_headings: anchor_headings).html_safe
  end

  # The shared post-sanitize prose pipeline, applied to BOTH the markdown path
  # (AI/imported content) and rendered rich text (a lesson edited in Lexxy). It
  # operates on already-sanitized HTML and only ADDS our own trusted markup, so a
  # `> [!ВАЖНО]` quote becomes a coloured callout, code blocks get copy-buttons,
  # tables scroll, and `## ` headings get anchors — identically, whichever editor
  # produced the section. A blockquote whose first line isn't a known marker is
  # left untouched, so plain quotes still work.
  def enrich_prose(html, anchor_headings: false)
    html = render_callouts(html)
    html = wrap_prose_tables(html)
    html = wrap_code_blocks(html)
    html = wrap_figures(html)
    html = anchor_prose_headings(html) if anchor_headings
    html
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
      label = %(<p class="callout__label">#{icon_tag(cfg[:icon])}<span>#{cfg[:label]}</span></p>)
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
    html = html.gsub(%r{<p>(<img\b[^>]*?>)\s*(?:<br\s*/?>\s*)?(?:<em>(.*?)</em>)?</p>(?:\s*<p><em>(.*?)</em></p>)?}m) do
      image = Regexp.last_match(1)
      caption = Regexp.last_match(2).presence || Regexp.last_match(3)
      pending = placeholder_image?(image)
      figure = +%(<figure class="prose-figure#{" prose-figure--pending" if pending}">#{pending ? pending_illustration(image) : image})
      figure << %(<figcaption class="prose-figure__caption">#{caption}</figcaption>) if caption.present?
      figure << "</figure>"
      figure
    end
    # A placeholder <img> not caught above (e.g. inline, no caption) still 404s —
    # swap it too, so a not-yet-drawn illustration never shows a broken-image icon.
    html.gsub(%r{<img\b[^>]*?>}) { |img| placeholder_image?(img) ? pending_illustration(img) : img }
  end

  # An illustration the author has only briefed, not drawn: a "TODO-*.png" src
  # 404s; a "placeholder: …" src is stripped by the sanitizer, leaving a src-less
  # <img>. Either way it's a not-yet-drawn image, not a broken asset.
  def placeholder_image?(img_tag)
    src = img_tag[/\ssrc=(["'])(.*?)\1/, 2]
    src.blank? || src.match?(/\ATODO/i)
  end

  # Calm dashed stand-in for a pending illustration — the same muted box the
  # rich-text path shows for a missing attachment (.attachment__missing), so the
  # markdown and editor paths look identical. The author's alt brief rides along
  # as the accessible label. Runs post-sanitize, so aria-* survive.
  def pending_illustration(img_tag)
    alt = img_tag[/\salt=(["'])(.*?)\1/, 2]
    label = alt.present? ? %( role="img" aria-label="#{alt}" title="#{alt}") : ""
    %(<span class="attachment__missing"#{label}>Иллюстрация готовится</span>)
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
      %(<span class="code-copy__icon code-copy__icon--copy">#{icon_tag("copy")}</span>) +
      %(<span class="code-copy__icon code-copy__icon--done">#{icon_tag("check")}</span>) +
      %(</button>)

    # Matches both highlighted (`<pre class="highlight">`) and plain `<pre>` code
    # blocks — in prose, every <pre> is a code block.
    html.gsub(%r{<pre[^>]*>.*?</pre>}m) do |pre|
      %(<div class="code-block" data-controller="copy-code">#{pre}#{button}</div>)
    end
  end

  # Whether the image variant processor (libvips via ruby-vips) can actually run
  # here. True in production (libvips is in the Dockerfile); false on a box
  # without the system lib (e.g. a no-sudo dev machine). The blob partial uses
  # this to serve a resized WebP where it can and fall back to the original where
  # it can't — so uploaded images display everywhere, not just in production.
  # Memoised on the module (probed once per process).
  def self.variant_processing_available?
    return @variant_processing_available unless @variant_processing_available.nil?

    @variant_processing_available =
      begin
        require "vips"
        true
      rescue LoadError
        false
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

  # Bump when the rendering pipeline (markdown/enrich_prose/callouts/…) changes,
  # so cached HTML below is regenerated even though the lesson itself didn't
  # change. View fragment caching gets this free via template digests; a helper
  # cache needs it spelled out.
  LESSON_CONTENT_RENDER_VERSION = 4

  # The HTML a reader sees for a section. Rich text (Lexxy) and the markdown
  # fallback both flow through the SAME enrichment, so callouts/code/tables/TOC
  # anchors render the same way regardless of which editor wrote the section.
  #
  # Rendering is the expensive part of a lesson view (Kramdown + Nokogiri +
  # enrichments), and a lesson is read far more than written — so the result is
  # cached in Solid Cache, keyed on the lesson's version (an edit creates a
  # revision, which touches the lesson, busting the key — see LessonRevision).
  # The per-request memo stays as an L1 cache: the body is read twice (prose +
  # TOC anchors), so this avoids even the cache round-trip the second time.
  def lesson_content(lesson, field)
    @lesson_content ||= {}
    @lesson_content[[ lesson.id, field ]] ||=
      Rails.cache.fetch([ lesson.cache_key_with_version, "lesson_content", field, LESSON_CONTENT_RENDER_VERSION ]) do
        rich = lesson.send(:"rich_#{field}")
        if rich.present?
          enrich_prose(rich.to_s, anchor_headings: field == :body)
        else
          markdown(lesson.send(field), anchor_headings: field == :body)
        end
      end.to_s.html_safe
  end

  # Entries for the right-rail "В этой статье" TOC: the body's ## headings.
  # Works for rich text and markdown alike — both now flow through enrich_prose,
  # which anchors every <h2>, so the rail no longer degrades on edited lessons.
  def lesson_toc(lesson)
    return [] unless lesson.has_body?
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

  # Resource-type badge (roadmap.sh-style): a coloured pill with an icon and
  # the kind label — the library and admin lists. One hue per kind — the "type"
  # axis. Lesson rows render the same axis as a bare coloured glyph instead
  # (resources/_resource + .lesson-resource__marker).
  RESOURCE_KIND_BADGES = {
    "norm" => { modifier: "badge--norm", icon: "file-text", label: "norm" },
    "book" => { modifier: "badge--book", icon: "book-open", label: "book" },
    "doc" => { modifier: "badge--doc", icon: "clipboard-text", label: "doc" },
    "course" => { modifier: "badge--course", icon: "graduation-cap", label: "course" },
    "video" => { modifier: "badge--video", icon: "video-camera", label: "video" },
    "article" => { modifier: "badge--article", icon: "newspaper", label: "article" },
    "software" => { modifier: "badge--software", icon: "cpu", label: "software" },
    "tool" => { modifier: "badge--tool", icon: "wrench", label: "tool" }
  }.freeze

  # A `document` resource is either an official standard ("Норматив") or a
  # book/handbook ("Книга"). We can't tell from `kind` alone, so we sniff the
  # title: anything starting like a Russian regulation is a norm, else a book.
  NORMATIVE_TITLE = /\A\s*(ГОСТ|ПУЭ|ПТЭЭП|ПТЭ|ПОТ[\s\d]|СП[\s\d]|СНиП|СО[\s\d]|РД[\s\d]|СанПиН|ВСН[\s\d]|ОСТ[\s\d]|Приказ|Федеральн|ФЗ[\s-]|Технический регламент|Правила|Приложение|Инструкция|Типов|Межотраслев|Профессиональн|Профстандарт|ANSI|ASME|EEMUA|ISA[\s-]|IEC[\s\d]|ISO[\s\d]|EN[\s\d]|DIN[\s\d]|API[\s\d]|NFPA|МЭК)/i

  def resource_kind_badge(resource)
    meta = resource_badge_meta(resource)
    label = t("lessons.resource_kinds.#{meta[:label]}", default: meta[:label].to_s.humanize)
    # Icon + word: the label keeps the type intuitive for everyone (no reliance on
    # learning icons or on hover, which mobile lacks).
    tag.span(class: "badge #{meta[:modifier]} lesson-resource__badge") do
      safe_join([ icon_tag(meta[:icon]), tag.span(label) ])
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

  # The admin "published vs draft" pill shown on paths/courses/lessons/posts
  # list rows. `published` is the caller's own check (`status == "published"`,
  # `post.published?`, …) since what counts as published varies slightly by model.
  def status_badge(label, published:)
    tag.span(label, class: "badge #{published ? 'badge--link' : 'badge--draft'}")
  end
end
