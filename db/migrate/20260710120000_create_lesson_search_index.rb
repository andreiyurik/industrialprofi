class CreateLessonSearchIndex < ActiveRecord::Migration[8.1]
  def change
    create_virtual_table :lesson_search_index, :fts5, [
      "title",
      "description",
      "body",
      "lesson_id UNINDEXED",
      "tokenize = 'unicode61 remove_diacritics 2'"
    ]
  end
end
