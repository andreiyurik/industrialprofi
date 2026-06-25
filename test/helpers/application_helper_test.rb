require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "markdown renders bold text" do
    assert_includes markdown("**bold**"), "<strong>"
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

  test "markdown renders links" do
    result = markdown("[link](https://example.com)")
    assert_includes result, '<a href="https://example.com"'
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

  test "markdown returns empty string for nil" do
    assert_equal "", markdown(nil)
  end

  test "markdown returns empty string for blank" do
    assert_equal "", markdown("")
    assert_equal "", markdown("   ")
  end
end
