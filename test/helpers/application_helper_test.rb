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

  test "markdown renders links" do
    result = markdown("[link](https://example.com)")
    assert_includes result, '<a href="https://example.com"'
  end

  test "markdown renders code blocks" do
    result = markdown("```ruby\nputs 'hi'\n```")
    assert_includes result, "<code"
  end

  test "markdown returns empty string for nil" do
    assert_equal "", markdown(nil)
  end

  test "markdown returns empty string for blank" do
    assert_equal "", markdown("")
    assert_equal "", markdown("   ")
  end
end
