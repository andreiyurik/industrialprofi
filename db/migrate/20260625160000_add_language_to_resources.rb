class AddLanguageToResources < ActiveRecord::Migration[8.1]
  # A source-language marker, orthogonal to the resource type. nil = Russian (the
  # default market language); "en"/"de" flag a foreign-language source with no
  # Russian equivalent, shown as a small secondary badge.
  def change
    add_column :resources, :language, :string
  end
end
