require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "generates a transliterated slug from the title on create" do
    post = Post.create!(title: "Свежая новость", status: "draft")
    assert_equal "svezhaya-novost", post.slug
  end

  test "published scope returns only published posts with a date" do
    assert_includes Post.published, posts(:published)
    assert_not_includes Post.published, posts(:draft)

    dateless = Post.create!(title: "Без даты", status: "published")
    assert_not_includes Post.published, dateless
    assert_not dateless.published?
  end

  test "recent orders newest first" do
    assert_equal posts(:also_published), Post.published.recent.first
  end

  test "to_param is the slug" do
    assert_equal posts(:published).slug, posts(:published).to_param
  end

  test "rejects a hero image that is too large" do
    post = posts(:draft)
    post.hero_image.attach(
      io: StringIO.new("x" * (LessonImageUpload::MAX_BYTES + 1)),
      filename: "big.png", content_type: "image/png"
    )
    assert_not post.valid?
    assert_includes post.errors.attribute_names, :hero_image
  end
end
