class AddRaisedPathStageToLessonSuggestions < ActiveRecord::Migration[8.1]
  def change
    add_column :lesson_suggestions, :raised_path_stage, :integer
  end
end
