class AddLearningGoalToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :learning_goal, :text
  end
end
