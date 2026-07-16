module Admin
  # News is site-wide official content (no Path scope, no trust-ladder review) —
  # authored by an administrator, so it's gated tighter than the editor CRUD.
  class PostsController < AdministratorController
    before_action :set_post, only: %i[edit update destroy]

    def index
      @posts = Post.recent
    end

    def new
      @post = Post.new(status: "draft")
    end

    def create
      @post = Post.new(post_params)
      stamp_published_at
      if @post.save
        redirect_to edit_admin_post_path(@post), notice: t("flash.post_created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @post.assign_attributes(post_params)
      stamp_published_at
      if @post.save
        redirect_to edit_admin_post_path(@post), notice: t("flash.post_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy!
      redirect_to admin_posts_path, notice: t("flash.post_deleted")
    end

    private
      def set_post
        @post = Post.find_by!(slug: params[:slug])
      end

      # Publishing sets the timeline date once; re-editing a live post keeps it.
      def stamp_published_at
        @post.published_at ||= Time.current if @post.status == "published"
      end

      def post_params
        permitted = [ :title, :excerpt, :status, :rich_body, :hero_image ]
        permitted << :slug unless slug_locked?(@post)
        params.require(:post).permit(*permitted)
      end
  end
end
