module Admin::EditorHelper
  # Routes uploads through the validating, size-capped Admin::UploadsController and wires the
  # client-side size pre-check; spread onto both the lesson and news editors so they stay in sync.
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
