# Policy for editor-uploaded lesson images — the single home for what the gated
# upload endpoint accepts and what the editor form advertises, so enforcement
# (Admin::UploadsController) and the editor's allowlist/hint can't drift.
#
# The cap is generous on purpose: readers are served a resized WebP variant,
# never the original, so an author can drop a raw phone photo without fighting a
# size wall. SVG is intentionally excluded — it can carry script (XSS), and
# diagrams stay the curated public/ commit, never an upload.
module LessonImageUpload
  PERMITTED_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_BYTES = 10.megabytes

  def self.permits?(content_type:, byte_size:)
    PERMITTED_TYPES.include?(content_type) && byte_size.to_i <= MAX_BYTES
  end

  def self.accept_attribute
    PERMITTED_TYPES.join(" ")
  end

  # The blob a reader will be SERVED, for the markdown fill flow — whose src is
  # baked into the lesson text, so there's no per-render variant branch to hide
  # behind. Transcode once at upload (bounded WebP) where vips exists; keep the
  # file as-is where it doesn't (a dev box) or for GIFs (animation would be lost).
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
