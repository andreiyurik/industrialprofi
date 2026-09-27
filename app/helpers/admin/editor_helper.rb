module Admin::EditorHelper
  # Routes uploads through the validating, size-capped Admin::UploadsController and wires the
  # client-side size pre-check; spread onto both the lesson and news editors so they stay in sync.
  def lexxy_image_options
    max_bytes = LessonImageUpload::MAX_BYTES
    {
      "permitted-attachment-types" => LessonImageUpload::PERMITTED_TYPES.join(" "),
      data: {
        direct_upload_url: admin_uploads_path,
        controller: "lexxy-uploads",
        "lexxy-uploads-max-bytes-value": max_bytes,
        "lexxy-uploads-message-value": t("admin.uploads.too_large", max: number_to_human_size(max_bytes))
      }
    }
  end

  # Lexxy imports a plain <img> as image/* and drops it as not permitted, so images arrive as attachments.
  def editor_html(markdown)
    return "" if markdown.blank?

    html = sanitize(Lesson.encode_placeholder_srcs(Kramdown::Document.new(markdown, input: "GFM").to_html),
      tags: ApplicationHelper::MARKDOWN_TAGS, attributes: ApplicationHelper::MARKDOWN_ATTRS)
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css("img").each do |img|
      if (attachment = editor_attachment_for(img))
        img.replace(attachment.node)
      end
    end
    fragment.to_html
  end

  private
    def editor_attachment_for(img)
      src = img["src"].to_s
      return if src.blank? || src.start_with?("data:")

      if (blob = IllustrationCensus.proxy_blob(src))
        Lesson.image_attachment(blob, caption: take_figure_caption(img))
      else
        caption = Lesson.placeholder_src?(src) ? img["alt"] : take_figure_caption(img)
        ActionText::Attachment.from_attributes({ "url" => src, "caption" => caption, "content-type" => editor_image_type(src) }.compact)
      end
    end

    # Only labels an existing URL for Lexxy's allowlist; uploads are checked separately.
    def editor_image_type(src)
      type = Marcel::MimeType.for(name: File.basename(Lesson.decode_placeholder(src).sub(/[?#].*/, "")))
      LessonImageUpload::PERMITTED_TYPES.include?(type) ? type : "image/png"
    end

    def take_figure_caption(img)
      br = img.next_element
      em = br&.next_element
      return unless br&.name == "br" && em&.name == "em" && em.next_sibling.nil?

      em.text.tap { [ br, em ].each(&:remove) }
    end
end
