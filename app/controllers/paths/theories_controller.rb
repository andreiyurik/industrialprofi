# «Теория» tab: chapters in reading order with lessons/tasks in place; paths#show
# keeps only the outline.
class Paths::TheoriesController < ApplicationController
  include PathScoped

  allow_unauthenticated_access
  before_action :set_path, :set_progress

  def show
    load_curriculum
  end
end
