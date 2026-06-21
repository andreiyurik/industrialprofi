require "test_helper"

class PhotoOptimizerTest < ActiveSupport::TestCase
  def image_upload
    Rack::Test::UploadedFile.new(file_fixture("photo.png"), "image/png")
  end

  test "passes blank attachables through unchanged" do
    assert_equal "", PhotoOptimizer.optimize("")
    assert_nil PhotoOptimizer.optimize(nil)
  end

  test "passes non-image uploads through unchanged" do
    upload = Rack::Test::UploadedFile.new(file_fixture("not_image.txt"), "text/plain")
    assert_same upload, PhotoOptimizer.optimize(upload)
  end

  test "passes oversize images through so the model's size validation rejects them" do
    oversize = Struct.new(:content_type, :size, :tempfile, :original_filename)
      .new("image/jpeg", PhotoOptimizer::MAX_INPUT_BYTES + 1, Tempfile.new, "big.jpg")
    assert_same oversize, PhotoOptimizer.optimize(oversize)
  end

  test "re-encodes an in-range image as stripped webp" do
    skip "libvips not available on this machine" unless PhotoOptimizer::VIPS_AVAILABLE

    result = PhotoOptimizer.optimize(image_upload)

    assert_kind_of Hash, result
    assert_equal "image/webp", result[:content_type]
    assert result[:filename].end_with?(".webp")
  end
end
