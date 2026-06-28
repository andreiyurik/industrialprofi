class AllowNullResourceUrl < ActiveRecord::Migration[8.1]
  def change
    change_column_null :resources, :url, true
  end
end
