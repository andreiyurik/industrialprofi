require "test_helper"

class Path::LandingTest < ActiveSupport::TestCase
  test "list slots edit as one item per line and round-trip as arrays" do
    path = paths(:electrician)
    path.update!(highlights_text: "Читает схемы\n\n  Находит неисправность  \n", pros_text: "", about: "  Текст  ")

    assert_equal [ "Читает схемы", "Находит неисправность" ], path.reload.highlights
    assert_equal "Читает схемы\nНаходит неисправность", path.highlights_text
    assert_nil path.pros, "a blank list is dropped, not stored as []"
    assert_equal "Текст", path.about, "text slots are stripped"
    assert path.landing_present?
  end

  test "an empty landing is absent, not a set of blanks" do
    path = paths(:welder)
    path.update!(about: "  ", highlights_text: "\n\n", cover_credit: "")

    assert_equal({}, path.reload.landing)
    assert_not path.landing_present?
  end

  test "lists are bounded" do
    path = paths(:electrician)
    path.highlights = Array.new(Path::Landing::MAX_ITEMS + 1) { "пункт" }
    assert_not path.valid?
    assert path.errors[:highlights].any?
  end

  test "faq_entries splits ### questions from their answers, or stays empty without headings" do
    path = paths(:electrician)
    path.faq = "Вступление.\n### Сколько учиться?\nГод.\n\nИли два.\n### С чего начать?\nС первой главы."
    assert_equal [ [ "Сколько учиться?", "Год.\n\nИли два." ], [ "С чего начать?", "С первой главы." ] ], path.faq_entries

    path.faq = "Просто абзац без вопросов."
    assert_empty path.faq_entries
  end

  test "normalize_landing keeps only known slots, as strings and arrays" do
    normalized = Path.normalize_landing("about" => " Кто это ", "highlights" => [ " a ", "", nil, "b" ],
                                        "pros" => nil, "bogus" => "x", "cover_credit" => "Фото: N")
    assert_equal({ "about" => "Кто это", "highlights" => %w[a b], "cover_credit" => "Фото: N" }, normalized)
  end

  test "the cover must be a raster image within the upload policy" do
    path = paths(:electrician)
    path.cover.attach(io: File.open(Rails.root.join("test/fixtures/files/cover.png")), filename: "cover.png", content_type: "image/png")
    assert path.valid?

    path.cover.attach(io: StringIO.new("<svg/>"), filename: "cover.svg", content_type: "image/svg+xml")
    assert_not path.valid?
    assert path.errors[:cover].any?
  end
end
