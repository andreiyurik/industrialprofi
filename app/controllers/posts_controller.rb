class PostsController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    @posts = Post.published.recent.includes(hero_image_attachment: :blob)
  end

  def show
    @post = Post.published.find_by!(slug: params[:slug])
    @older_post = @post.older
    @newer_post = @post.newer
  end
end
