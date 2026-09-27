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

  # Editor input, not reader output: no enrich wrappers, and placeholders arrive in the attachment
  # shape Lexxy keeps — a concrete image type and a URI-safe (percent-encoded) src.
  def editor_html(markdown)
    return "" if markdown.blank?

    slots = markdown.scan(Lesson::PENDING_IMAGE_PATTERN)
    html = sanitize(Kramdown::Document.new(markdown, input: "GFM").to_html,
      tags: ApplicationHelper::MARKDOWN_TAGS, attributes: ApplicationHelper::MARKDOWN_ATTRS)
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css("img").select { |img| img["src"].blank? || img["src"].match?(Lesson::PENDING_SRC) }
            .zip(slots) do |img, (brief, src)|
      next unless src
      img.replace(ActionText::HtmlConversion.create_element(ActionText::Attachment.tag_name,
        "url" => ERB::Util.url_encode(src), "caption" => brief, "content-type" => "image/png"))
    end
    fragment.to_html
  end
end
