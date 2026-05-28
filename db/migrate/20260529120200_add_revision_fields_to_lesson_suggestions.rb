class AddRevisionFieldsToLessonSuggestions < ActiveRecord::Migration[8.1]
  def change
    add_column :lesson_suggestions, :edit_reason, :text
    add_column :lesson_suggestions, :base_content, :text
  end
end
