# The «Теория» tab of a profession hub: the programme — chapters in reading
# order, each with its lessons and the practice tasks in their place — under
# the shared hub header. The overview (paths#show) keeps only the outline.
class Paths::TheoriesController < ApplicationController
  include PathScoped

  allow_unauthenticated_access
  before_action :set_path, :set_progress

  def show
    load_curriculum
  end
end
