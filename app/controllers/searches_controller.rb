class SearchesController < ApplicationController
  allow_unauthenticated_access

  # Live typing sends a request per pause; 60/min is ample for a human and
  # caps what a scripted client can burn. Counter lives in Solid Cache.
  rate_limit to: 60, within: 1.minute, only: :show

  def show
    @query = params[:q].to_s.strip
    @results = LessonSearch.new(@query).results
    render :palette if turbo_frame_request_id == "palette_results"
  end
end
