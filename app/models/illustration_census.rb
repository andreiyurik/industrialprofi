# One profession's illustration health, computed live from the same rendered
# sections a reader sees (rich text when present, the markdown fallback
# otherwise) — nothing is stored, so the census can't drift from the content.
# Briefs are unfilled placeholder stand-ins, images are the real ones, and a
# broken image is a local reference whose file is gone from disk.
class IllustrationCensus
  SECTIONS = %w[description body task].freeze
  MARKDOWN_IMAGE = /!\[(?<alt>[^\]]*)\]\((?<src>[^)]+)\)/

  Image = Data.define(:lesson, :section, :src, :alt, :blob) do
    def external? = src.to_s.match?(%r{\Ahttps?://}i)

    # Only local files can be verified without a network call. Blobs exist by
    # construction — purging one removes the attachment with it.
    def broken?
      blob.nil? && !external? && !IllustrationCensus.public_file?(src)
    end
  end

  def self.public_file?(src)
    relative = src.to_s.sub(/[?#].*/, "").delete_prefix("/")
    full = File.expand_path(relative, Rails.public_path.to_s)
    full.start_with?(Rails.public_path.to_s) && File.file?(full)
  end

  # An <img src> written by the fill flow: a permanent ActiveStorage proxy URL.
  # Resolving it back to the blob makes the census treat it like any uploaded
  # image (live, thumbnail-able); a purged blob honestly comes back nil → broken.
  PROXY_SRC = %r{\A/rails/active_storage/blobs/proxy/(?<signed_id>[^/]+)/}

  def self.proxy_blob(src)
    signed_id = src.to_s[PROXY_SRC, :signed_id]
    ActiveStorage::Blob.find_signed(signed_id) if signed_id
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def initialize(path)
    @path = path
  end

  # [[lesson, slot], ...] in curriculum order — the fill-me queue. Each slot
  # carries the src that Lesson#fill_illustration! matches on.
  def briefs
    @briefs ||= lessons.flat_map do |lesson|
      lesson.illustration_slots.map { |slot| [ lesson, slot ] }
    end
  end

  def images = @images ||= lessons.flat_map { |lesson| lesson_images(lesson) }
  def broken = @broken ||= images.select(&:broken?)
  def live   = @live ||= images.reject(&:broken?)

  private
    def lessons
      @lessons ||= @path.lessons.ordered.with_all_rich_text.to_a
    end

    def lesson_images(lesson)
      SECTIONS.flat_map { |section| section_images(lesson, section) }
              .uniq { |image| [ image.src, image.blob&.id ] }
    end

    # Mirrors Revisable#section_html precedence: the rich text is what the
    # reader sees once it exists; the markdown column only counts before that.
    def section_images(lesson, section)
      rich = lesson.public_send(:"rich_#{section}")
      if rich&.body.present?
        rich_images(lesson, section, rich.body)
      else
        markdown_images(lesson, section, lesson.public_send(section).to_s)
      end
    end

    def rich_images(lesson, section, body)
      attached = body.attachables.grep(ActiveStorage::Blob).select(&:image?).map do |blob|
        Image.new(lesson:, section:, src: nil, alt: blob.filename.to_s, blob:)
      end
      inline = Nokogiri::HTML.fragment(body.to_html).css("img").map do |img|
        Image.new(lesson:, section:, src: img["src"], alt: img["alt"].to_s,
                  blob: IllustrationCensus.proxy_blob(img["src"]))
      end
      attached + inline
    end

    def markdown_images(lesson, section, markdown)
      markdown.scan(MARKDOWN_IMAGE).filter_map do |alt, src|
        next if src.match?(/\A\s*(TODO|placeholder)/i) # a brief, not an image
        src = src.strip
        Image.new(lesson:, section:, src:, alt:, blob: IllustrationCensus.proxy_blob(src))
      end
    end
end
