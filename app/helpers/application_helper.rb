module ApplicationHelper
  def icon_tag(name, **options)
    tag.span class: class_names("icon icon--#{name}", options.delete(:class)), "aria-hidden": true, **options
  end

  def in_admin?
    controller.is_a?(Admin::BaseController)
  end

  LOCALE_NAMES = { ru: "Рус", en: "Eng" }.freeze

  def native_locale_name(locale)
    LOCALE_NAMES.fetch(locale, locale.to_s)
  end

  def locale_switch_url(locale)
    bilingual_page? ? url_for(locale: locale) : root_path(locale: locale)
  end

  # div/span+class stay allowed for rouge's token classes — safe since content is reviewed.
  MARKDOWN_TAGS = %w[h1 h2 h3 h4 h5 h6 p ul ol li a strong em code pre kbd blockquote table thead tbody tr th td hr br img div span].freeze
  MARKDOWN_ATTRS = %w[href src alt target rel class].freeze

  CALLOUTS = {
    "ОПАСНО"  => { mod: "danger",    icon: "warning",      label: "Опасно" },
    "ВАЖНО"   => { mod: "important", icon: "info",         label: "Важно" },
    "СОВЕТ"   => { mod: "tip",       icon: "lightbulb",    label: "Совет" },
    "ПРИМЕР"  => { mod: "example",   icon: "calculator",   label: "Разобранный пример" },
    "ПРОВЕРЬ" => { mod: "check",     icon: "check-circle", label: "Проверь себя" }
  }.freeze

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

  def markdown(text, anchor_headings: false, fill_links_for: nil)
    return "" if text.blank?
    html = Kramdown::Document.new(text, input: "GFM",
      syntax_highlighter: "rouge",
      syntax_highlighter_opts: { formatter: RougeFormatter }).to_html
    html = sanitize(html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRS)
    enrich_prose(html, anchor_headings: anchor_headings, fill_links_for: fill_links_for).html_safe
  end

  # fill_links_for: only from reader-facing renders — must never leak into content that gets STORED.
  def enrich_prose(html, anchor_headings: false, fill_links_for: nil)
    html = render_callouts(html)
    html = wrap_prose_tables(html)
    html = wrap_code_blocks(html)
    html = wrap_figures(html, fill_links_for: fill_links_for)
    html = anchor_prose_headings(html) if anchor_headings
    html
  end

  # ASCII-only: Cyrillic breaks Turbo's scroll-to-anchor and makes URLs percent-soup.
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

      body = inner.sub(%r{\[!#{type}\]\s*(?:<br\s*/?>\s*)?}, "").gsub(%r{<p>\s*</p>}, "")
      label = %(<p class="callout__label">#{icon_tag(cfg[:icon])}<span>#{cfg[:label]}</span></p>)
      %(<div class="callout callout--#{cfg[:mod]}">#{label}#{body}</div>)
    end
  end

  def wrap_prose_tables(html)
    html.gsub("<table>", '<div class="prose-table"><table>')
        .gsub("</table>", "</table></div>")
  end

  def wrap_figures(html, fill_links_for: nil)
    html = html.gsub(%r{<p>(<img\b[^>]*?>)\s*(?:<br\s*/?>\s*)?(?:<em>(.*?)</em>)?</p>(?:\s*<p><em>(.*?)</em></p>)?}m) do
      image = Regexp.last_match(1)
      caption = Regexp.last_match(2).presence || Regexp.last_match(3)
      pending = placeholder_image?(image)
      figure = +%(<figure class="prose-figure#{" prose-figure--pending" if pending}">#{pending ? pending_illustration(image, fill_links_for) : image})
      figure << %(<figcaption class="prose-figure__caption">#{caption}</figcaption>) if caption.present?
      figure << "</figure>"
      figure
    end
    html.gsub(%r{<img\b[^>]*?>}) { |img| placeholder_image?(img) ? pending_illustration(img, fill_links_for) : img }
  end

  def placeholder_image?(img_tag)
    src = img_tag[/\ssrc=(["'])(.*?)\1/, 2]
    src.blank? || src.match?(/\ATODO/i)
  end

  # Fill link ships in cached HTML for everyone, hidden by CSS — the real gate is server-side.
  def pending_illustration(img_tag, lesson = nil)
    alt = img_tag[/\salt=(["'])(.*?)\1/, 2]
    src = img_tag[/\ssrc=(["'])(.*?)\1/, 2]
    label = alt.present? ? %( role="img" aria-label="#{alt}" title="#{alt}") : ""
    box = %(<span class="attachment__missing"#{label}>Иллюстрация готовится</span>)
    return box unless lesson

    # Keyword arg: a positional lesson would be swallowed by the route's optional :locale segment.
    slot_params = src.present? ? { src: src } : { brief: alt }
    box + link_to(new_admin_lesson_illustration_path(lesson_slug: lesson.slug, **slot_params), class: "attachment__fill") do
      safe_join([ icon_tag("plus-circle"), tag.span(t("lessons.fill_illustration")) ])
    end
  end

  def wrap_code_blocks(html)
    button =
      %(<button type="button" class="code-copy" hidden ) +
      %(data-copy-code-target="button" data-action="copy-code#copy" ) +
      %(aria-label="Копировать код" title="Копировать код">) +
      %(<span class="code-copy__icon code-copy__icon--copy">#{icon_tag("copy")}</span>) +
      %(<span class="code-copy__icon code-copy__icon--done">#{icon_tag("check")}</span>) +
      %(</button>)

    html.gsub(%r{<pre[^>]*>.*?</pre>}m) do |pre|
      %(<div class="code-block" data-controller="copy-code">#{pre}#{button}</div>)
    end
  end

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

  # A missing asset must never 500 the whole lesson.
  def safe_remote_image_tag(remote_image)
    image_tag(remote_image.url, width: remote_image.try(:width), height: remote_image.try(:height),
              loading: "lazy", alt: remote_image.try(:caption).to_s)
  rescue Propshaft::MissingAssetError
    tag.span(t("lessons.image_pending"), class: "attachment__missing")
  end

  # Bump when the render pipeline changes — template-digest busting doesn't reach a helper cache.
  LESSON_CONTENT_RENDER_VERSION = 5

  def lesson_content(lesson, field)
    @lesson_content ||= {}
    @lesson_content[[ lesson.id, field ]] ||=
      Rails.cache.fetch([ lesson.cache_key_with_version, "lesson_content", field, LESSON_CONTENT_RENDER_VERSION ]) do
        rich = lesson.send(:"rich_#{field}")
        if rich.present?
          enrich_prose(rich.to_s, anchor_headings: field == :body, fill_links_for: lesson)
        else
          markdown(lesson.send(field), anchor_headings: field == :body, fill_links_for: lesson)
        end
      end.to_s.html_safe
  end

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

  NORMATIVE_TITLE = /\A\s*(ГОСТ|ПУЭ|ПТЭЭП|ПТЭ|ПОТ[\s\d]|СП[\s\d]|СНиП|СО[\s\d]|РД[\s\d]|СанПиН|ВСН[\s\d]|ОСТ[\s\d]|Приказ|Федеральн|ФЗ[\s-]|Технический регламент|Правила|Приложение|Инструкция|Типов|Межотраслев|Профессиональн|Профстандарт|ANSI|ASME|EEMUA|ISA[\s-]|IEC[\s\d]|ISO[\s\d]|EN[\s\d]|DIN[\s\d]|API[\s\d]|NFPA|МЭК)/i

  def resource_kind_badge(resource)
    meta = resource_badge_meta(resource)
    label = t("lessons.resource_kinds.#{meta[:label]}", default: meta[:label].to_s.humanize)
    tag.span(class: "badge #{meta[:modifier]} lesson-resource__badge") do
      safe_join([ icon_tag(meta[:icon]), tag.span(label) ])
    end
  end

  def resource_badge_meta(resource)
    return RESOURCE_KIND_BADGES[resource.kind] if RESOURCE_KIND_BADGES.key?(resource.kind)

    if resource.title.to_s.match?(NORMATIVE_TITLE)
      RESOURCE_KIND_BADGES["norm"]
    else
      RESOURCE_KIND_BADGES["book"]
    end
  end

  def status_badge(label, published:)
    tag.span(label, class: "badge #{published ? 'badge--link' : 'badge--draft'}")
  end
end
