module Admin
  class PathsController < BaseController
    before_action :set_path, only: %i[edit update]

    def index
      @paths = Path.editable_by(Current.user).ordered
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
        grant_editorship(@path)
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
      authorize_path!(@path)
    end

    # An editor who creates a profession owns it from then on; admins edit
    # everything, so they don't accumulate grants they don't need.
    def grant_editorship(path)
      Current.user.editorships.create(path:) unless Current.user.administrator?
    end

    # status is handled separately via sanitized_status (trust ladder); slug is
    # locked once the path is live (see slug_locked?).
    def path_params
      permitted = [ :title, :description ]
      permitted << :slug unless slug_locked?(@path)
      params.require(:path).permit(*permitted)
    end
  end
end
