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

  def initialize(path)
    @path = path
  end

  # [[lesson, brief], ...] in curriculum order — the fill-me queue.
  def briefs
    @briefs ||= lessons.flat_map do |lesson|
      lesson.pending_illustration_briefs.map { |brief| [ lesson, brief ] }
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
      Image.new(lesson:, section:, src: img["src"], alt: img["alt"].to_s, blob: nil)
    end
    attached + inline
  end

  def markdown_images(lesson, section, markdown)
    markdown.scan(MARKDOWN_IMAGE).filter_map do |alt, src|
      next if src.match?(/\A\s*(TODO|placeholder)/i) # a brief, not an image
      Image.new(lesson:, section:, src: src.strip, alt:, blob: nil)
    end
  end
end
