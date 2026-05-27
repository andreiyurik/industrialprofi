class ChangeBodyMarkdownNullableOnLessonSuggestions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :lesson_suggestions, :body_markdown, true
  end
end
