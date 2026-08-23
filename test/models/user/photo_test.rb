require "test_helper"

class User::PhotoTest < ActiveSupport::TestCase
  def upload(content_type) = Rack::Test::UploadedFile.new(file_fixture("cover.png"), content_type)

  test "update_photo stores one square WebP, never the original" do
    user = users(:editor)
    assert user.update_photo(upload("image/png"))

    blob = user.photo.blob
    assert_equal "image/webp", blob.content_type
    require "vips"
    image = Vips::Image.new_from_buffer(blob.download, "")
    assert_equal [ User::Photo::SIZE, User::Photo::SIZE ], [ image.width, image.height ]
    assert_operator blob.byte_size, :<, 50.kilobytes
  end

  test "update_photo refuses anything but an image within the cap" do
    user = users(:editor)
    assert_not user.update_photo(upload("text/plain"))
    assert user.errors[:photo].any?
    assert_not user.photo.attached?
  end

  test "only grant holders show a photo" do
    member = users(:member)
    member.photo.attach(io: File.open(file_fixture("cover.png")), filename: "cover.png", content_type: "image/png")
    assert_not member.shows_photo?
    assert users(:editor).tap { |u| u.update_photo(upload("image/png")) }.shows_photo?
  end
end
