require "test_helper"

class LessonImageUploadTest < ActiveSupport::TestCase
  test "permits a small raster image" do
    assert LessonImageUpload.permits?(content_type: "image/png", byte_size: 500.kilobytes)
    assert LessonImageUpload.permits?(content_type: "image/webp", byte_size: 9.megabytes)
  end

  test "refuses oversized, non-image, and SVG" do
    assert_not LessonImageUpload.permits?(content_type: "image/png", byte_size: 11.megabytes)
    assert_not LessonImageUpload.permits?(content_type: "application/pdf", byte_size: 1.kilobyte)
    assert_not LessonImageUpload.permits?(content_type: "image/svg+xml", byte_size: 1.kilobyte)
  end

  test "accept_attribute lists the permitted types comma-separated, as HTML requires" do
    assert_equal "image/png,image/jpeg,image/webp,image/gif", LessonImageUpload.accept_attribute
  end

  test "rejection judges the bytes, not the browser's content type" do
    assert_nil LessonImageUpload.rejection(upload("cover.png"))
    assert_equal :not_image, LessonImageUpload.rejection(upload("not_an_image.png"))
    assert_equal :not_image, LessonImageUpload.rejection(upload("scheme.svg"))
    assert_equal :not_image, LessonImageUpload.rejection(nil)
  end

  test "reader_ready_blob transcodes a PNG the browser called a GIF" do
    skip "no libvips here" unless ApplicationHelper.variant_processing_available?

    assert_equal "image/webp", LessonImageUpload.reader_ready_blob(upload("cover.png", "image/gif")).content_type
  end

  private
    def upload(name, content_type = "image/png")
      Rack::Test::UploadedFile.new(file_fixture(name), content_type)
    end
end
