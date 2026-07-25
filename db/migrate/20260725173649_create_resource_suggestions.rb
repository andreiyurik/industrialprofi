class CreateResourceSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :resource_suggestions do |t|
      t.references :lesson, null: false, foreign_key: true
      # Optional like LessonSuggestion#user — a suggestion outlives the account.
      t.references :user, null: true, foreign_key: true
      t.string :author_name, null: false
      t.string :url, null: false
      t.string :title, null: false
      t.string :kind, null: false, default: "article"
      t.string :note
      t.string :status, null: false, default: "pending"
      t.text :reviewer_comment
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :resource_suggestions, :status
  end
end
