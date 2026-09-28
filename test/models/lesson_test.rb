require "test_helper"

class LessonTest < ActiveSupport::TestCase
  # Validations

  test "valid with required attributes" do
    lesson = Lesson.new(course: courses(:el_basics), title: "Новый урок", slug: "novyy-urok")
    assert lesson.valid?
  end

  # Fail-safe provenance: a row created outside the importer defaults to "human",
  # so unknown-origin content is treated as frozen and never overwritten.
  test "origin defaults to human" do
    assert_equal "human", Lesson.new.origin
    assert_equal "human", Path.new.origin
    assert_equal "human", Course.new.origin
    assert_equal "human", Resource.new.origin
  end

  test "invalid without course" do
    lesson = Lesson.new(title: "Orphan", slug: "orphan")
    assert_not lesson.valid?
    assert lesson.errors[:course].any?
  end

  test "derives path from course" do
    lesson = Lesson.new(course: courses(:el_basics), title: "X", slug: "x-derives")
    lesson.valid?
    assert_equal paths(:electrician), lesson.path
  end

  test "invalid without title" do
    lesson = Lesson.new(path: paths(:electrician), slug: "no-title")
    assert_not lesson.valid?
    assert lesson.errors[:title].any?
  end

  test "auto-generates a slug from the title when blank" do
    lesson = Lesson.new(course: courses(:el_basics), title: "Новый Урок")
    assert lesson.valid?
    assert_equal "novyy-urok", lesson.slug
  end

  test "invalid without path" do
    lesson = Lesson.new(title: "Orphan", slug: "orphan")
    assert_not lesson.valid?
    assert lesson.errors[:path].any?
  end

  test "slug must be unique" do
    lesson = Lesson.new(path: paths(:electrician), title: "Dup", slug: lessons(:pteep).slug)
    assert_not lesson.valid?
    assert lesson.errors[:slug].any?
  end

  test "slug rejects invalid format" do
    lesson = Lesson.new(path: paths(:electrician), title: "Test", slug: "BAD SLUG")
    assert_not lesson.valid?
    assert lesson.errors[:slug].any?
  end

  test "position must be non-negative" do
    lesson = Lesson.new(path: paths(:electrician), title: "Test", slug: "neg-pos", position: -1)
    assert_not lesson.valid?
    assert lesson.errors[:position].any?
  end

  # Associations

  test "belongs to path" do
    assert_equal paths(:electrician), lessons(:pteep).path
  end

  test "belongs to course" do
    assert_equal courses(:el_basics), lessons(:pteep).course
  end

  test "has many resources" do
    assert_equal 2, lessons(:pteep).resources.count
  end

  test "destroying lesson destroys resources" do
    assert_difference "Resource.count", -2 do
      lessons(:pteep).destroy
    end
  end

  # to_param

  test "to_param returns slug" do
    assert_equal "pteep-osnovy", lessons(:pteep).to_param
  end

  # missing_self_check? (drives content:audit)

  test "missing_self_check? is true for a written theory lesson without a self-check block" do
    lesson = Lesson.new(course: courses(:el_basics), title: "T", slug: "t-no-check",
                        body: "Объяснение темы без вопросов.")
    assert lesson.missing_self_check?
  end

  test "missing_self_check? is false when the body has a self-check block" do
    lesson = Lesson.new(course: courses(:el_basics), title: "T", slug: "t-with-check",
                        body: "Объяснение.\n\n> [!ПРОВЕРЬ] Что произойдёт, если...?")
    assert_not lesson.missing_self_check?
  end

  test "missing_self_check? is false for an unwritten lesson with no body yet" do
    lesson = Lesson.new(course: courses(:el_basics), title: "T", slug: "t-empty")
    assert_not lesson.missing_self_check?
  end

  # to_markdown

  test "to_markdown includes body" do
    lesson = lessons(:pteep)
    md = lesson.to_markdown
    assert_includes md, lesson.body
  end

  test "to_markdown includes title as heading" do
    lesson = lessons(:pteep)
    md = lesson.to_markdown
    assert_includes md, "# #{lesson.title}"
  end

  test "to_markdown includes description" do
    lesson = lessons(:pteep)
    md = lesson.to_markdown
    assert_includes md, lesson.description
  end

  test "to_markdown includes task" do
    lesson = lessons(:pteep)
    md = lesson.to_markdown
    assert_includes md, lesson.task
  end

  test "to_markdown omits blank sections" do
    lesson = Lesson.new(path: paths(:electrician), title: "Minimal", slug: "minimal", body: "Content here")
    md = lesson.to_markdown
    assert_includes md, "Content here"
    refute_includes md, "Задание"
  end

  # Revisions

  test "section_html falls back to rendered markdown" do
    assert_includes lessons(:pteep).section_html(:body), "Содержание урока по ПТЭЭП"
  end

  test "revise! applies content and records a revision" do
    lesson = lessons(:pteep)

    assert_difference -> { lesson.lesson_revisions.count }, 1 do
      lesson.revise!(section: "body", html: "<p>Свежий текст</p>",
                     editor_name: "Автор", edit_reason: "почему", source: "suggestion")
    end

    assert_includes lesson.reload.section_html(:body), "Свежий текст"
    revision = lesson.lesson_revisions.ordered.first
    assert_equal 1, revision.version
    assert_equal "Автор", revision.editor_name
    assert_equal "почему", revision.edit_reason
    assert_includes revision.content_after, "Свежий текст"
  end

  test "revise! increments version numbers" do
    lesson = lessons(:pteep)
    lesson.revise!(section: "body", html: "<p>один</p>", editor_name: "A", edit_reason: nil, source: "admin")
    lesson.revise!(section: "body", html: "<p>два</p>", editor_name: "A", edit_reason: nil, source: "admin")
    assert_equal [ 1, 2 ], lesson.lesson_revisions.order(:version).map(&:version)
  end

  test "admin_update_with_revisions! records only changed sections" do
    lesson = lessons(:pteep)

    assert_difference -> { lesson.lesson_revisions.count }, 1 do
      lesson.admin_update_with_revisions!(
        { rich_body: "<p>Совсем новое содержание</p>" }, edit_reason: "правка"
      )
    end

    revision = lesson.lesson_revisions.ordered.first
    assert_equal "body", revision.section
    assert_equal "admin", revision.source
  end

  test "admin_update_with_revisions! skips unchanged sections" do
    lesson = lessons(:pteep)
    assert_no_difference -> { lesson.lesson_revisions.count } do
      lesson.admin_update_with_revisions!({ title: "Переименовано" }, edit_reason: nil)
    end
    assert_equal "Переименовано", lesson.reload.title
  end

  test "revised? reflects revision count" do
    lesson = lessons(:pteep)
    refute lesson.revised?
    lesson.revise!(section: "body", html: "<p>x</p>", editor_name: "A", edit_reason: nil, source: "admin")
    assert lesson.reload.revised?
  end

  test "partitioning preloaded resources fires no extra query (hot-path guard)" do
    lesson = Lesson.includes(:resources).find(lessons(:pteep).id)
    assert_no_queries do
      lesson.resources.to_a.partition(&:required?)
    end
  end

  # Illustration slots + fill

  test "illustration_slots finds TODO and placeholder forms across body and task" do
    lesson = lessons(:pteep)
    lesson.update!(body: "Текст.\n\n![Схема допуска](TODO-elektrik-dopusk.png)\n\nЕщё.",
                   task: "![](placeholder: фото стенда)")

    slots = lesson.illustration_slots
    assert_equal [ %w[body TODO-elektrik-dopusk.png], [ "task", "placeholder: фото стенда" ] ],
                 slots.map { |slot| [ slot.section, slot.src ] }
    assert_equal "Схема допуска", slots.first.display_brief
    assert_equal "фото стенда", slots.last.display_brief
  end

  test "a placeholder slot with a brief keeps its src as illustrator instructions" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Щит](placeholder: щит в разрезе, вводной автомат сверху)\n\n![Схема](TODO-shema.png)")

    assert_equal [ "щит в разрезе, вводной автомат сверху", nil ], lesson.illustration_slots.map(&:instructions)
  end

  # The shape Lexxy keeps for a placeholder handed over by editor_html.
  RICH_PLACEHOLDER = %(<p>До.</p><action-text-attachment url="TODO-shema.png" caption="Схема допуска" content-type="image/png"></action-text-attachment><p>После.</p>)

  test "a placeholder kept through the editor stays in the fill queue" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема](TODO-shema.png)", rich_body: RICH_PLACEHOLDER)

    assert_equal [ [ "body", "Схема допуска", "TODO-shema.png" ] ],
                 lesson.reload.illustration_slots.map { |slot| [ slot.section, slot.brief, slot.src ] }
  end

  test "a placeholder: src survives the editor percent-encoded and fills by its original src" do
    lesson = lessons(:pteep)
    lesson.update!(rich_body: %(<action-text-attachment url="#{ERB::Util.url_encode("placeholder: щит")}" caption="Щит" content-type="image/png"></action-text-attachment>))
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"), filename: "shchit.webp", content_type: "image/webp")

    assert_equal [ "placeholder: щит" ], lesson.illustration_slots.map(&:src)
    lesson.fill_illustration!(src: "placeholder: щит", blob: blob)
    assert_equal blob, lesson.reload.rich_body.body.attachments.sole.attachable
  end

  test "a placeholder deleted in the editor drops out of the fill queue" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема](TODO-shema.png)", rich_body: "<p>Правленый текст</p>")

    assert_empty lesson.reload.illustration_slots
  end

  test "fill_illustration! swaps a rich placeholder for the image with the given caption, not the brief" do
    lesson = lessons(:pteep)
    lesson.update!(rich_body: RICH_PLACEHOLDER)
    blob = image_blob("shema.webp")

    assert_difference -> { lesson.lesson_revisions.count } => 1 do
      lesson.fill_illustration!(src: "TODO-shema.png", blob: blob, caption: "Рис. 1. Допуск")
    end

    lesson.reload
    attachment = lesson.rich_body.body.attachments.sole
    assert_equal blob, attachment.attachable
    assert_equal "Рис. 1. Допуск", attachment.caption
    assert_includes lesson.rich_body.body.to_plain_text, "После."
    assert_empty lesson.illustration_slots

    revision = lesson.lesson_revisions.last
    assert_includes revision.content_before, "TODO-shema.png"
    assert_includes revision.content_after, "sgid="
  end

  test "fill_illustration! without a caption leaves the image uncaptioned" do
    lesson = lessons(:pteep)
    lesson.update!(rich_body: RICH_PLACEHOLDER)

    lesson.fill_illustration!(src: "TODO-shema.png", blob: image_blob("shema.webp"), caption: " ")
    assert_nil lesson.reload.rich_body.body.attachments.sole.caption
  end

  test "fill_illustration! keeps asterisks in a rich caption but strips them from a Markdown one" do
    lesson = lessons(:pteep)
    lesson.update!(rich_body: RICH_PLACEHOLDER)
    lesson.fill_illustration!(src: "TODO-shema.png", blob: image_blob("shema.webp"), caption: "Сечение 4*16 мм")
    assert_equal "Сечение 4*16 мм", lesson.reload.rich_body.body.attachments.sole.caption

    lesson.update!(rich_body: nil, body: "![Схема](TODO-a.png)")
    lesson.fill_illustration!(src: "TODO-a.png", blob: image_blob("a.webp"), caption: "Сечение 4*16 мм")
    assert_includes lesson.reload.body, "*Сечение 416 мм*"
  end

  test "an emphasised word starting the next line is prose, not a placeholder caption" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема](TODO-a.png)\n*Важно* — соблюдайте допуск")

    assert_nil lesson.illustration_slots.sole.caption
    lesson.fill_illustration!(src: "TODO-a.png", blob: image_blob("a.webp"))
    assert_includes lesson.reload.body, "*Важно* — соблюдайте допуск"
  end

  test "fill_illustration! fills only the first of two placeholders sharing a src" do
    lesson = lessons(:pteep)
    placeholder = %(<action-text-attachment url="TODO" caption="Схема" content-type="image/png"></action-text-attachment>)
    lesson.update!(rich_body: placeholder + placeholder)

    lesson.fill_illustration!(src: "TODO", blob: image_blob("shema.webp"))
    assert_equal [ "TODO" ], lesson.reload.illustration_slots.map(&:src)
  end

  test "fill_illustration! on a stale copy keeps an image filled meanwhile" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Первая](TODO-1.png)\n\n![Вторая](TODO-2.png)")
    stale = Lesson.find(lesson.id)

    lesson.fill_illustration!(src: "TODO-1.png", blob: image_blob("1.webp"))
    stale.fill_illustration!(src: "TODO-2.png", blob: image_blob("2.webp"))

    assert_empty lesson.reload.illustration_slots
    assert_equal 2, lesson.body.scan("/rails/active_storage/blobs/proxy/").size
  end

  test "a placeholder src with parentheses is one slot and fills whole" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема](placeholder: точка P3 на отметке (62%); провода к электродам)\n\nПосле.")

    assert_equal [ "placeholder: точка P3 на отметке (62%); провода к электродам" ], lesson.illustration_slots.map(&:src)
    lesson.fill_illustration!(src: lesson.illustration_slots.sole.src, blob: image_blob("shema.webp"))
    assert_no_match(/провода|62%/, lesson.reload.body)
    assert_includes lesson.body, "После."
  end

  test "an italic line under a placeholder is its caption, and the fill keeps or replaces it" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема допуска: кто кого допускает](TODO-a.png)\n*Рис. 1. Допуск.*\n\n![Щит: вид спереди](TODO-b.png)")

    slots = lesson.illustration_slots
    assert_equal [ "Рис. 1. Допуск.", "Щит" ], slots.map(&:suggested_caption)

    lesson.fill_illustration!(src: "TODO-a.png", blob: image_blob("a.webp"), caption: "Рис. 1. Кто кого допускает")
    lesson.fill_illustration!(src: "TODO-b.png", blob: image_blob("b.webp"), caption: "")

    body = lesson.reload.body
    assert_match %r{\]\(/rails/[^)]+\)\n\*Рис\. 1\. Кто кого допускает\*\n\n!\[Щит}, body
    assert_not_includes body, "Рис. 1. Допуск."
    assert_match %r{\]\(/rails/[^)]+\)\z}, body
  end

  test "fill_illustration! swaps the placeholder for a proxy URL, attaches and records a revision" do
    lesson = lessons(:pteep)
    lesson.update!(body: "До.\n\n![Схема допуска](TODO-elektrik-dopusk.png)\n\nПосле.")
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"),
      filename: "dopusk.webp", content_type: "image/webp")

    assert_difference -> { lesson.lesson_revisions.count } => 1 do
      lesson.fill_illustration!(src: "TODO-elektrik-dopusk.png", blob: blob, edit_reason: "Иллюстрация")
    end

    lesson.reload
    assert_includes lesson.body, "](/rails/active_storage/blobs/proxy/"
    assert_not_includes lesson.body, "TODO-elektrik-dopusk.png"
    assert_includes lesson.body, "![Схема допуска]" # the brief becomes the alt
    assert lesson.illustrations.attached?
    assert_equal "human", lesson.origin
    assert_empty lesson.illustration_slots
  end

  test "fill_illustration! refuses honestly when the placeholder is gone" do
    lesson = lessons(:pteep)
    before = lesson.body
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"),
      filename: "x.webp", content_type: "image/webp")

    assert_raises(Lesson::PlaceholderMissing) do
      lesson.fill_illustration!(src: "TODO-net-takogo.png", blob: blob)
    end
    assert_equal before, lesson.reload.body
    assert_not lesson.illustrations.attached?
  end

  private
    def image_blob(filename)
      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"), filename:, content_type: "image/webp")
    end
end
