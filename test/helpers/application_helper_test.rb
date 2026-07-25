require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "markdown renders bold text" do
    assert_includes markdown("**bold**"), "<strong>"
  end

  # In dev/prod Propshaft raises on a missing asset (a not-yet-drawn "TODO-*.png");
  # the helper must swallow that and render a placeholder, not 500 the lesson.
  # (The test-env resolver is lenient and won't raise, so we force it.)
  test "safe_remote_image_tag renders a placeholder when the image asset is missing" do
    missing = Struct.new(:url, :width, :height, :caption).new("TODO-x.png", nil, nil, nil)
    define_singleton_method(:image_tag) { |*, **| raise Propshaft::MissingAssetError.new("TODO-x.png") }

    html = safe_remote_image_tag(missing)
    assert_includes html, "attachment__missing"
    assert_includes html, I18n.t("lessons.image_pending")
  end

  test "markdown renders heading" do
    result = markdown("## Title")
    assert_includes result, "<h2"
    assert_includes result, "Title"
  end

  test "markdown wraps a standalone image and its caption in one figure" do
    result = markdown("![схема](/lesson-images/net.svg)\n\n*Рис. 1. Сеть АСУ ТП.*")
    assert_includes result, '<figure class="prose-figure">'
    assert_includes result, "<img"
    assert_includes result, '<figcaption class="prose-figure__caption">Рис. 1. Сеть АСУ ТП.</figcaption>'
    # The caption is adopted into the figure, not left as a separate paragraph.
    assert_not_includes result, "<p><em>Рис. 1."
  end

  test "markdown wraps the caption even when it sits on the next line (no blank line)" do
    # How lessons are actually authored: image then *Рис…* directly below, so
    # kramdown joins them in one <p> with a <br>. The caption must still become a
    # <figcaption>, not stay as large inline italic body text.
    result = markdown("![схема](/lesson-images/net.svg)\n*Рис. 2. Сеть АСУ ТП.*")
    assert_includes result, '<figcaption class="prose-figure__caption">Рис. 2. Сеть АСУ ТП.</figcaption>'
    assert_not_includes result, "<br"
  end

  test "markdown wraps a caption-less image in a figure too" do
    result = markdown("![схема](/lesson-images/net.svg)")
    assert_includes result, '<figure class="prose-figure">'
    assert_not_includes result, "<figcaption"
  end

  test "markdown leaves an inline image untouched" do
    result = markdown("Вот картинка ![x](/a.png) внутри текста.")
    assert_not_includes result, "prose-figure"
  end

  test "a not-yet-drawn TODO placeholder renders a calm stand-in, never a broken img" do
    result = markdown("![Схема щита](TODO-elektrik-shchit.png)\n\n*Рис. 1. Щит.*")
    assert_includes result, "attachment__missing"
    assert_includes result, "Иллюстрация готовится"
    assert_includes result, "prose-figure--pending"
    assert_includes result, 'aria-label="Схема щита"' # the illustrator brief survives
    assert_not_includes result, "<img" # no 404-ing image tag reaches the reader
  end

  test "a bare 'placeholder:' src (stripped by the sanitizer) also becomes a stand-in" do
    result = markdown("![Схема](placeholder: художник рисует щит)")
    assert_includes result, "attachment__missing"
    assert_not_includes result, "<img"
  end

  test "markdown renders links" do
    result = markdown("[link](https://example.com)")
    assert_includes result, '<a href="https://example.com"'
  end

  test "markdown highlights Structured Text via the custom Rouge lexer" do
    result = markdown("```st\nIF Start AND NOT Stop THEN Motor := TRUE; END_IF\n```")
    assert_includes result, '<pre class="highlight">'
    assert_includes result, '<span class="k">IF</span>'      # keyword tokenized
    assert_includes result, '<span class="ow">AND</span>'    # word operator tokenized
  end

  test "markdown renders code blocks" do
    result = markdown("```ruby\nputs 'hi'\n```")
    assert_includes result, "<code"
  end

  test "markdown renders a typed callout with label" do
    result = markdown("> [!СОВЕТ]\n> Полезный совет.\n")
    assert_includes result, 'class="callout callout--tip"'
    assert_includes result, "Совет"
    assert_includes result, "Полезный совет."
  end

  test "callout body has no leading <br> from the GFM hard break" do
    # `[!ТИП]` and the body sit on two `>` lines; kramdown joins them with a
    # <br> that must be stripped, or it renders as a blank first line.
    result = markdown("> [!СОВЕТ]\n> Текст совета.\n")
    assert_no_match %r{<p>\s*<br}, result
    assert_includes result, "<p>Текст совета."
  end

  test "enrich_prose upgrades a Lexxy-style blockquote into a typed callout" do
    # A lesson edited in Lexxy stores a quote as <blockquote><p>…</p></blockquote>;
    # the marker on the first line must drive the same coloured callout the
    # markdown path produces, so authoring in either editor renders identically.
    html = "<blockquote><p>[!ВАЖНО] Группа III не даёт права работать в 6–10 кВ.</p></blockquote>"
    result = enrich_prose(html)
    assert_includes result, 'class="callout callout--important"'
    assert_includes result, "Важно"
    assert_includes result, "Группа III не даёт права работать в 6–10 кВ."
  end

  test "enrich_prose leaves an unmarked blockquote as a plain quote" do
    html = "<blockquote><p>Обычная цитата без маркера.</p></blockquote>"
    result = enrich_prose(html)
    assert_includes result, "<blockquote>"
    assert_not_includes result, "callout"
  end

  test "markdown returns empty string for nil" do
    assert_equal "", markdown(nil)
  end

  test "markdown returns empty string for blank" do
    assert_equal "", markdown("")
    assert_equal "", markdown("   ")
  end
end
