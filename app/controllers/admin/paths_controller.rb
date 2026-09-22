module Admin
  class PathsController < BaseController
    before_action :set_path, only: %i[edit update destroy]

    def index
      @curated_ids = Current.user.editorships.pluck(:path_id).to_set
      @paths = Path.editable_by(Current.user).ordered
                   .sort_by { |path| [ @curated_ids.include?(path.id) ? 0 : 1, path.position ] }
    end

    # editable_by scopes this find; a non-owner editor 404s instead of seeing another workspace.
    def show
      @path = Path.editable_by(Current.user).find_by!(slug: params[:slug])
      @courses = @path.courses.ordered.includes(:lessons)
      @editorships = @path.editorships.includes(:user).joins(:user).merge(User.order(:name))
      @editorship_candidates = Editorship.candidates_for(@path) if Current.user.can_administer?
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
        record_admin_action("path_created", target: @path, subject: @path.title, status: @path.status)
        notify_review_request(@path)
        redirect_to edit_admin_path_path(@path), notice: I18n.t("flash.path_created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def destroy
      return redirect_to(admin_path_path(@path), alert: t("auth.not_authorized")) unless Current.user.can_administer?

      # Preloads courses→lessons→resources so the destroy cascade doesn't N+1 crawl.
      @path = Path.includes(courses: { lessons: [ :resources, :lesson_suggestions, :resource_suggestions ] }).find(@path.id)
      @path.destroy!
      record_admin_action("path_deleted", subject: @path.title)
      redirect_to admin_paths_path, notice: I18n.t("flash.path_deleted")
    end

    def update
      @path.assign_attributes(path_params)
      @path.status = sanitized_status(params.dig(:path, :status), current: @path.status_was)

      if @path.save
        @path.cover.purge_later if params.dig(:path, :remove_cover) == "1"
        log_and_notify_status_change(@path, "path_status_changed", subject: @path.title)
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

    def grant_editorship(path)
      Current.user.editorships.create(path:) unless Current.user.administrator?
    end

    # status excluded — handled via sanitized_status (trust ladder), not raw params.
    def path_params
      permitted = [ :title, :description, :icon,
                    :cover, :cover_credit, :about, :history, :faq, :highlights_text, :pros_text, :cons_text ]
      permitted << :slug unless slug_locked?(@path)
      params.require(:path).permit(*permitted)
    end
  end
end
