require "test_helper"

class Admin::EditorHelperTest < ActionView::TestCase
  test "editor_html hands placeholders over as attachments with their original src and brief" do
    assert_equal [ [ "TODO-shema.png", "Схема" ], [ "placeholder: щит (вид спереди)", "Щит" ] ],
                 placeholders_in(editor_html("![Схема](TODO-shema.png)\n\n![Щит](placeholder: щит (вид спереди))"))
  end

  test "editor_html pairs each placeholder with its own image, whatever surrounds it" do
    html = editor_html("Пиши так: `![бриф](TODO-x.png)`\n\n![лого]()\n\n![Щит](TODO-shchit.png)")

    assert_equal [ [ "TODO-shchit.png", "Щит" ] ], placeholders_in(html)
    assert_includes html, "<code>![бриф](TODO-x.png)</code>"
  end

  test "editor_html hands a filled image over as its blob, with the italic line as caption" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("cover.png").open, filename: "shchit.png", content_type: "image/png")
    url = rails_service_blob_proxy_path(blob.signed_id, blob.filename)

    content = ActionText::Content.new(editor_html("![Щит в разрезе](#{url})\n*Рис. 2. Щит.*\n\nПосле."))

    attachment = content.attachments.sole
    assert_equal blob, attachment.attachable
    assert_equal "Рис. 2. Щит.", attachment.caption
    assert_not_includes content.to_html, "<em>"
  end

  test "editor_html keeps a committed diagram with a type Lexxy permits" do
    attachment = ActionText::Content.new(editor_html("![Схема](/lesson-images/elektrik/shema.svg)")).attachments.sole

    assert_equal "/lesson-images/elektrik/shema.svg", attachment.node["url"]
    assert_includes LessonImageUpload::PERMITTED_TYPES, attachment.node["content-type"]
  end

  test "editor_html keeps the alt of a real image as its caption when no italic line gives one" do
    attachment = ActionText::Content.new(editor_html("![Схема заземления в разрезе](/lesson-images/elektrik/shema.svg)")).attachments.sole

    assert_equal "Схема заземления в разрезе", attachment.caption
  end

  test "editor_html carries no reader-only wrappers" do
    html = editor_html("> [!ПРОВЕРЬ]\n> Вопрос?\n\n![Схема](TODO-shema.png)")

    assert_includes html, "<blockquote>"
    assert_not_includes html, "callout"
    assert_not_includes html, "attachment__missing"
    assert_not_includes html, I18n.t("lessons.image_pending")
  end

  private
    def placeholders_in(html)
      ActionText::Content.new(html).attachments.map { [ Lesson.decode_placeholder(it.node["url"]), it.caption ] }
    end
end
