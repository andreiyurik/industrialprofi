class AddDifficultyToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :difficulty, :string

    # Practice lessons must always carry a difficulty; seeds refine the value.
    reversible do |dir|
      dir.up { execute "UPDATE lessons SET difficulty = 'beginner' WHERE kind = 'practice'" }
    end
  end
end
