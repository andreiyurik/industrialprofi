require "test_helper"

class MetaTagsHelperTest < ActionView::TestCase
  test "meta_title sets content_for title and og_title" do
    meta_title("Test Title")
    assert_equal "Test Title — industrialprofi.com", content_for(:title)
    assert_equal "Test Title — industrialprofi.com", content_for(:og_title)
  end

  test "meta_description sets content_for" do
    meta_description("Some description")
    assert_equal "Some description", content_for(:description)
    assert_equal "Some description", content_for(:og_description)
  end
end
