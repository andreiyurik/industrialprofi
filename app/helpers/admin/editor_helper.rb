module Admin::EditorHelper
  # Shared options for a Lexxy rich_text_area that permits image uploads: routes
  # them through the validating, size-capped Admin::UploadsController and wires
  # the client-side size pre-check (lexxy-uploads controller). Spread onto the
  # field — `f.rich_text_area :rich_body, class: "lexxy-content", **lexxy_image_options`
  # — so the lesson and news editors stay in sync from one definition.
  def lexxy_image_options
    max_bytes = LessonImageUpload::MAX_BYTES
    {
      "permitted-attachment-types" => LessonImageUpload.accept_attribute,
      data: {
        direct_upload_url: admin_uploads_path,
        controller: "lexxy-uploads",
        "lexxy-uploads-max-bytes-value": max_bytes,
        "lexxy-uploads-message-value": t("admin.uploads.too_large", max: number_to_human_size(max_bytes))
      }
    }
  end
end
