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
end
