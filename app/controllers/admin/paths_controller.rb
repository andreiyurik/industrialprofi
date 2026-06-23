module Admin
  class PathsController < BaseController
    before_action :set_path, only: %i[edit update]

    def index
      @paths = Path.ordered
    end

    def new
      @path = Path.new(status: "draft")
    end

    def create
      @path = Path.new(path_params)
      @path.author_id = Current.user.id
      @path.position = (Path.maximum(:position) || 0) + 1
      @path.status = sanitized_status(params.dig(:path, :status), current: "draft")

      if @path.save
        redirect_to edit_admin_path_path(@path), notice: I18n.t("flash.path_created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @path.assign_attributes(path_params)
      @path.status = sanitized_status(params.dig(:path, :status), current: @path.status_was)

      if @path.save
        redirect_to edit_admin_path_path(@path), notice: I18n.t("flash.path_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_path
      @path = Path.find_by!(slug: params[:slug])
    end

    # status is handled separately via sanitized_status (trust ladder).
    def path_params
      params.require(:path).permit(:title, :slug, :description)
    end
  end
end
