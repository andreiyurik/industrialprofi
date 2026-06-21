class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.text :body
      t.string :page_url
      t.datetime :read_at

      t.timestamps
    end
  end
end
