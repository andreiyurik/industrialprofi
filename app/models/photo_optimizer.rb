# Downscales and re-encodes an uploaded image BEFORE Active Storage ever stores
# it, so the full-resolution original from a phone (3–6 MB) never lands on disk
# — on a one-server SQLite app, unbounded photo growth is the one real threat to
# the disk, and the disk is the app's life. Each image is fit to MAX_EDGE,
# re-encoded as WebP (~QUALITY) with all metadata stripped (a ~10–15× size cut,
# and EXIF/GPS stripping is a privacy win for the journal). A PORO, like
# RevisionDiff — no gem, no service-object ceremony.
#
# Degrades exactly like the thumbnail helper: without libvips (a dev box) every
# attachable passes through UNCHANGED. Anything we don't or can't optimize
# (blanks, non-images, oversize uploads, processing failures) also passes
# through untouched, so JournalEntry's own validations still see the original
# and behave precisely as before.
class PhotoOptimizer
  MAX_EDGE = 1600
  QUALITY = 80
  # Above this we don't process (avoid feeding a huge image to libvips); the
  # original passes through and JournalEntry's size validation rejects it.
  MAX_INPUT_BYTES = JournalEntry::MAX_PHOTO_SIZE

  # Mirror ApplicationHelper::THUMBNAILS_AVAILABLE: image processing needs
  # libvips, which ships in the production image but not necessarily on a dev box.
  VIPS_AVAILABLE = begin
    require "image_processing/vips"
    true
  rescue LoadError, StandardError
    false
  end

  def self.optimize(attachable)
    new(attachable).optimize
  end

  def initialize(attachable)
    @attachable = attachable
  end

  def optimize
    return @attachable unless VIPS_AVAILABLE && optimizable?

    processed = ImageProcessing::Vips
      .source(@attachable.tempfile)
      .resize_to_limit(MAX_EDGE, MAX_EDGE)
      .convert("webp")
      .saver(quality: QUALITY, strip: true)
      .call

    { io: processed.tap(&:rewind), filename: webp_filename, content_type: "image/webp" }
  rescue => e
    # Never lose a user's upload to an optimizer hiccup — fall back to the original.
    Rails.logger.warn("PhotoOptimizer skipped a photo: #{e.class}: #{e.message}")
    @attachable
  end

  private
    def optimizable?
      @attachable.respond_to?(:content_type) &&
        @attachable.content_type.to_s.start_with?("image/") &&
        @attachable.respond_to?(:tempfile) &&
        @attachable.respond_to?(:size) &&
        @attachable.size.to_i.between?(1, MAX_INPUT_BYTES)
    end

    def webp_filename
      base = File.basename(@attachable.original_filename.to_s, ".*").presence || "photo"
      "#{base}.webp"
    end
end
