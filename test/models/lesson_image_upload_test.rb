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

  test "accept_attribute lists the permitted types space-separated" do
    assert_equal "image/png image/jpeg image/webp image/gif", LessonImageUpload.accept_attribute
  end
end
