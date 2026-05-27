module Admin
  class PathsController < BaseController
    before_action :set_path, only: %i[edit update]

    def index
      @paths = Path.ordered
    end

    def edit; end

    def update
      if @path.update(path_params)
        redirect_to edit_admin_path_path(@path), notice: I18n.t("flash.path_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_path
      @path = Path.find_by!(slug: params[:slug])
    end

    def path_params
      params.require(:path).permit(:title, :slug, :description, :status)
    end
  end
end
