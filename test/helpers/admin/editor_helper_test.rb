require "test_helper"

class Admin::EditorHelperTest < ActionView::TestCase
  test "editor_html hands placeholders over as attachments with their original src" do
    content = ActionText::Content.new(editor_html("![Схема](TODO-shema.png)\n\n![Щит](placeholder: щит в разрезе)"))

    assert_equal [ [ "TODO-shema.png", "Схема" ], [ "placeholder: щит в разрезе", "Щит" ] ],
                 content.attachments.map { |attachment| [ Lesson.placeholder_src(attachment), attachment.caption ] }
  end

  test "editor_html carries no reader-only wrappers" do
    html = editor_html("> [!ПРОВЕРЬ]\n> Вопрос?\n\n![Схема](TODO-shema.png)")

    assert_includes html, "<blockquote>"
    assert_not_includes html, "callout"
    assert_not_includes html, "attachment__missing"
    assert_not_includes html, "Иллюстрация готовится"
  end
end
