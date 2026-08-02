require "test_helper"

# The editor's stylesheets are the one part of our CSS a reader never gets
# (StylesheetsHelper), so a page that hosts an editor has to ask for them by
# hand. Forget the line and nothing raises — the editor just renders unstyled.
# This is the tripwire for that.
class EditorStylesheetsTest < ActiveSupport::TestCase
  VIEWS = Rails.root.join("app/views")

  test "every view with a rich text editor asks for the editor stylesheets" do
    unmarked = Dir[VIEWS.join("**/*.erb")].select do |file|
      source = File.read(file)
      source.include?("rich_text_area") && !source.include?("content_for :rich_text_editor")
    end

    assert_empty unmarked.map { |file| Pathname(file).relative_path_from(Rails.root).to_s },
      "Редактор без своих стилей: добавьте `<% content_for :rich_text_editor, true %>`"
  end
end
