class MapsController < ApplicationController
  rate_limit to: 30, within: 1.hour, only: %i[ create update ],
             with: -> { redirect_to dashboard_path, alert: t("auth.rate_limited") }

  before_action :set_map, only: %i[ edit update destroy ]

  # The map is an overlay on the profession's lessons (see Map), not a copy —
  # this writes no item rows at all.
  def create
    return redirect_to(edit_map_path) if Current.user.map

    base = Path.published.localized.find_by!(slug: params[:path])
    Map.create!(user: Current.user, path: base,
                title: t("maps.default_title", path: base.title, name: Current.user.first_name))
    Current.user.ensure_handle!
    flash[:map_welcome] = true
    redirect_to edit_map_path, notice: t(".created")
  end

  def edit
    load_checklist
  end

  def update
    if @map.update(map_params)
      @map.choose_lessons!(Array(params[:lesson_ids]), notes: lesson_notes)
      redirect_to profile_map_path(@map), notice: t(".updated")
    else
      load_checklist
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @map.destroy
    redirect_to dashboard_path, notice: t(".deleted")
  end

  private
    def set_map
      @map = Current.user.map or raise ActiveRecord::RecordNotFound
    end

    def load_checklist
      return unless (base = @map.path)

      @courses = base.courses.published.ordered.includes(:lessons)
      @excluded_ids = @map.excluded_lesson_ids
      @extras = @map.extras_by_lesson
    end

    # lessons[<id>][note] — the author's one-line comment per kept lesson.
    def lesson_notes
      params.fetch(:lessons, {}).each_pair.to_h { |id, attrs| [ id.to_i, attrs[:note].to_s ] }
    end

    def map_params
      params.expect(map: [ :title, :description,
                           items_attributes: [ [ :id, :title, :url, :note, :after_lesson_id, :position, :_destroy ] ] ])
    end
end
