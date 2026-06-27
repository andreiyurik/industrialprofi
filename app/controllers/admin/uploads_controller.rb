module Admin
  # Image uploads for lesson rich text, gated to editors/admins (it lives in the
  # admin namespace, so BaseController#ensure_can_edit_content runs first). This
  # closes the hole where any member could POST straight to the open
  # ActiveStorage direct-upload endpoint: lesson images are bounded, trusted
  # content, so only the trust ladder writes them to the SQLite disk.
  #
  # Mirrors ActiveStorage::DirectUploadsController#create but refuses anything
  # that isn't a small raster image. SVG is deliberately excluded — it can carry
  # script (XSS), and diagrams stay the curated public/ commit, never an upload.
  class UploadsController < BaseController
    # The direct-upload URL the Disk service signs is built from the request
    # host — ActiveStorage's own controller sets this; we inherit ApplicationController, so opt in.
    include ActiveStorage::SetCurrent

    def create
      args = blob_args
      unless LessonImageUpload.permits?(content_type: args[:content_type], byte_size: args[:byte_size])
        return render json: { error: t("admin.uploads.rejected", max: helpers.number_to_human_size(LessonImageUpload::MAX_BYTES)) },
                      status: :unprocessable_entity
      end

      blob = ActiveStorage::Blob.create_before_direct_upload!(**args)
      render json: direct_upload_json(blob)
    end

    private
      def blob_args
        params.expect(blob: [ :filename, :byte_size, :checksum, :content_type, metadata: {} ]).to_h.symbolize_keys
      end

      def direct_upload_json(blob)
        blob.as_json(root: false, methods: :signed_id).merge(direct_upload: {
          url: blob.service_url_for_direct_upload,
          headers: blob.service_headers_for_direct_upload
        })
      end
  end
end
