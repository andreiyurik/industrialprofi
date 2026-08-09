class PostsController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    # The index cards are text-only — hero images render on the show page.
    @posts = Post.published.recent
  end

  def show
    @post = Post.published.find_by!(slug: params[:slug])
    @older_post = @post.older
    @newer_post = @post.newer
  end
end
