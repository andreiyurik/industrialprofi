class LearningGoalsController < ApplicationController
  def edit
  end

  def update
    if Current.user.update(learning_goal_params)
      redirect_to dashboard_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def learning_goal_params
      params.expect(user: [ :learning_goal ])
    end
end
