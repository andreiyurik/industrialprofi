class ChangesController < ApplicationController
  allow_unauthenticated_access

  LIMIT = 50

  def index
    @revisions = LessonRevision.in_catalog
                               .includes(:lesson).order(created_at: :desc, id: :desc).limit(LIMIT).load
  end
end
