# Single home for what uploads accept — enforcement (Admin::UploadsController) and the
# editor form can't drift. SVG excluded (XSS risk); cap is generous since readers get a
# resized WebP, never the original.
module LessonImageUpload
  PERMITTED_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_BYTES = 10.megabytes

  def self.permits?(content_type:, byte_size:)
    PERMITTED_TYPES.include?(content_type) && byte_size.to_i <= MAX_BYTES
  end

  def self.accept_attribute
    PERMITTED_TYPES.join(" ")
  end

  # Baked into lesson markdown as a static src, so no per-render variant branch.
  # Transcodes to bounded WebP where vips exists; GIFs and vips-less boxes keep the original.
  def self.reader_ready_blob(upload)
    if ApplicationHelper.variant_processing_available? && upload.content_type != "image/gif"
      require "image_processing/vips"
      processed = ImageProcessing::Vips.source(upload.tempfile)
        .resize_to_limit(1600, 1600).convert("webp").saver(quality: 82).call
      ActiveStorage::Blob.create_and_upload!(io: processed,
        filename: "#{File.basename(upload.original_filename, '.*')}.webp",
        content_type: "image/webp")
    else
      ActiveStorage::Blob.create_and_upload!(io: upload,
        filename: upload.original_filename, content_type: upload.content_type)
    end
  end
end
