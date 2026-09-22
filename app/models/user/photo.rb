# Storage is bounded by grants, not users — members keep the generated disc.
# Upload is resized to one SIZE-square WebP and stripped of EXIF/GPS; the original never touches disk.
module User::Photo
  extend ActiveSupport::Concern

  SIZE = 256

  included do
    has_one_attached :photo, dependent: :purge_later
  end

  def photo_allowed? = can_edit_content?

  def shows_photo? = photo_allowed? && photo.attached?

  # Same allowlist as lesson images (LessonImageUpload).
  def update_photo(upload)
    unless LessonImageUpload.permits?(content_type: upload.content_type, byte_size: upload.size)
      errors.add(:photo, :invalid)
      return false
    end

    require "image_processing/vips"
    square = ImageProcessing::Vips.source(upload.tempfile).resize_to_fill(SIZE, SIZE)
                                  .convert("webp").saver(quality: 82, strip: true).call
    photo.attach(io: square, filename: "photo.webp", content_type: "image/webp")
    true
  rescue Vips::Error
    errors.add(:photo, :invalid)
    false
  end
end
