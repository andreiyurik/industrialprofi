module Lesson::Illustratable
  extend ActiveSupport::Concern

  PENDING_IMAGE_PATTERN = /!\[(?<brief>[^\]]*)\]\(\s*(?<src>(?:TODO|placeholder)(?:[^()]|\([^()]*\))*?)\s*\)/i
  PENDING_FIGURE_PATTERN = /#{PENDING_IMAGE_PATTERN}(?:[ \t]*\n\*(?<caption>[^*\n]+)\*(?=[ \t]*$))?/
  PENDING_SRC = /\A\s*(?:TODO|placeholder)/i

  IllustrationSlot = Data.define(:section, :brief, :src, :caption) do
    def display_brief = brief.presence || src.sub(/\A(?:TODO[-_]?|placeholder:?)\s*/i, "").presence
    def instructions = (src[/\Aplaceholder:\s*(.+)/im, 1] if brief.present?)
    def suggested_caption = caption.presence || brief.to_s[/\A[^:;—(]+/].to_s.strip.truncate(120, separator: " ")
  end

  class PlaceholderMissing < StandardError; end

  class_methods do
    # Every byte escaped: sanitizers read even «placeholder%3A» as a URI scheme and drop the src.
    def encode_placeholder_srcs(html)
      return html unless html.include?("<img")

      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css("img[src]").each { |img| img["src"] = encode_placeholder(img["src"]) if placeholder_src?(img["src"]) }
      fragment.to_html
    end

    def encode_placeholder(src) = src.to_s.bytes.map { format("%%%02X", it) }.join

    def decode_placeholder(src)
      URI.decode_uri_component(src.to_s).then { it.valid_encoding? ? it : src.to_s }
    rescue ArgumentError
      src.to_s
    end

    def placeholder_src?(src) = decode_placeholder(src).match?(PENDING_SRC)

    def placeholder_node?(node) = node["sgid"].blank? && placeholder_src?(node["url"])

    # With a url, as Lexxy's own uploads carry: without one Lexxy imports a custom node and drops the caption.
    def image_attachment(blob, caption:)
      ActionText::Attachment.from_attachable(blob, caption:, url: Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true))
    end
  end

  def illustration_slots
    %w[body task].flat_map do |section|
      if (rich = public_send(:"rich_#{section}")).present?
        rich.body.fragment.find_all("action-text-attachment").select { Lesson.placeholder_node?(it) }.map do |node|
          IllustrationSlot.new(section:, brief: node["caption"].to_s, src: Lesson.decode_placeholder(node["url"]), caption: nil)
        end
      else
        public_send(section).to_s.scan(PENDING_FIGURE_PATTERN).map do |brief, src, caption|
          IllustrationSlot.new(section:, brief:, src:, caption:)
        end
      end
    end
  end

  def pending_illustration_briefs = illustration_slots.map(&:brief)

  def fill_illustration!(src:, blob:, caption: nil, edit_reason: nil)
    caption = caption.to_s.squish.presence

    with_lock do
      slot = illustration_slots.find { |candidate| candidate.src == src }
      raise PlaceholderMissing, src.to_s unless slot

      illustrations.attach(blob)
      before = section_html(slot.section)
      if (rich = public_send(:"rich_#{slot.section}")).present?
        fill_rich_placeholder(rich, slot, blob, caption)
      else
        fill_markdown_placeholder(slot, blob, caption)
      end
      self.origin = "human"
      save!
      # Not admin_update_with_revisions! — its diff is blind to a src-only change.
      record_revision!(section: slot.section, before: before, after: section_html(slot.section),
        editor_name: nil, edit_reason: edit_reason, source: "admin")
    end
  end

  private
    def fill_rich_placeholder(rich, slot, blob, caption)
      filled = false
      rich.body = rich.body.render_attachments do |attachment|
        next attachment.node if filled || !Lesson.placeholder_node?(attachment.node) ||
          Lesson.decode_placeholder(attachment.node["url"]) != slot.src

        filled = true
        Lesson.image_attachment(blob, caption:).node
      end
    end

    def fill_markdown_placeholder(slot, blob, caption)
      url = Rails.application.routes.url_helpers.rails_service_blob_proxy_path(blob.signed_id, blob.filename)
      caption = caption&.gsub(/[*\\]/, "")&.squish.presence
      text = public_send(slot.section).dup
      match = text.to_enum(:scan, PENDING_FIGURE_PATTERN).map { Regexp.last_match }.find { it[:src] == slot.src }
      text[match.begin(0)...match.end(0)] = "![#{match[:brief]}](#{url})#{"\n*#{caption}*" if caption}"
      public_send(:"#{slot.section}=", text)
    end
end
