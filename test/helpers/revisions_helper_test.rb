require "test_helper"

class RevisionsHelperTest < ActionView::TestCase
  # The side-by-side view renders a reader's proposed HTML, which may carry raw
  # markup from the kramdown fallback — it must be sanitised.
  test "safe_prose keeps prose and callouts but strips scripts" do
    html = safe_prose(%(<p>текст</p><div class="callout callout--tip">совет</div><script>alert(1)</script>))
    assert_includes html, "<p>текст</p>"
    assert_includes html, "callout--tip"
    assert_not_includes html, "<script>"
  end
end
