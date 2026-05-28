require "test_helper"

class RevisionDiffTest < ActiveSupport::TestCase
  test "marks inserted words with ins" do
    html = RevisionDiff.new("<p>раз два</p>", "<p>раз два три</p>").to_html
    assert_includes html, "<ins>"
    assert_includes html, "три"
    assert_not_includes html, "<del>"
  end

  test "marks removed words with del" do
    html = RevisionDiff.new("<p>раз два три</p>", "<p>раз три</p>").to_html
    assert_includes html, "<del>"
    assert_includes html, "два"
  end

  test "unchanged text carries no diff markers" do
    html = RevisionDiff.new("<p>одно и то же</p>", "<p>одно и то же</p>").to_html
    assert_not_includes html, "<ins>"
    assert_not_includes html, "<del>"
  end

  test "identical? ignores html representation differences" do
    diff = RevisionDiff.new("<p>текст урока</p>", "текст урока")
    assert diff.identical?
  end

  test "identical? is false when words change" do
    refute RevisionDiff.new("<p>текст</p>", "<p>другой текст</p>").identical?
  end

  test "escapes html so output is safe" do
    html = RevisionDiff.new("", "<p>a &amp; <script>b</script></p>").to_html
    assert_includes html, "&amp;"
    assert_not_includes html, "<script>"
  end

  test "treats blank snapshots as empty" do
    html = RevisionDiff.new(nil, "<p>новое</p>").to_html
    assert_includes html, "<ins>"
    assert_includes html, "новое"
  end
end
