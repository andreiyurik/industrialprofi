module Admin
  class PreviewController < BaseController
    def create
      html = helpers.markdown(params[:text])
      render json: { html: html }
    end
  end
end
