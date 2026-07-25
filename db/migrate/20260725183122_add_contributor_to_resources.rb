class AddContributorToResources < ActiveRecord::Migration[8.1]
  def change
    # Both nullable: a resource authored/imported directly (founder, seed, AI)
    # has no community contributor — only one promoted from an approved
    # ResourceSuggestion carries a name, mirroring lesson_revisions.editor_name.
    add_column :resources, :contributor_name, :string
    add_reference :resources, :user, null: true, foreign_key: true
  end
end
