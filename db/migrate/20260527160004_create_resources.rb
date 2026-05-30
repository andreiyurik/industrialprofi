class CreateResources < ActiveRecord::Migration[8.1]
  def change
    create_table :resources do |t|
      t.references :lesson, null: false, foreign_key: true
      t.string :title, null: false
      t.string :url, null: false
      t.string :kind, null: false, default: "document"
      t.boolean :required, null: false, default: false
      t.string :country_code
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :resources, [ :lesson_id, :position ]
  end
end
