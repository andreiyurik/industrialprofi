# A curator's face next to their name — for people who hold a grant (editors,
# administrators); members keep the generated disc, so storage is bounded by
# grants, never by users. Only one SIZE-square WebP is ever kept: the upload is
# resized and stripped of metadata (EXIF/GPS) on the way in and the original
# never touches the disk.
module User::Photo
  extend ActiveSupport::Concern

  SIZE = 256

  included do
    has_one_attached :photo, dependent: :purge_later
  end

  def photo_allowed? = can_edit_content?

  def shows_photo? = photo_allowed? && photo.attached?

  # Same allowlist as lesson images (LessonImageUpload). Returns false — with an
  # error on :photo — for anything that isn't a readable image within the cap.
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
