module Admin
  # Gated to editors/admins — closes ActiveStorage's open direct-upload endpoint to any member.
  class UploadsController < BaseController
    # Disk service signs the upload URL from the request host, normally set by AS's own controller.
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
