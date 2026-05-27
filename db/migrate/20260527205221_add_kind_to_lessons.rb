class AddKindToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :kind, :string, null: false, default: "lesson"
  end
end
