class AddNoteToResources < ActiveRecord::Migration[8.1]
  def change
    add_column :resources, :note, :string
  end
end
