require "test_helper"

class GlossaryTermTest < ActiveSupport::TestCase
  test "needs a mark and its expansion, unique within the lesson" do
    term = lessons(:pteep).glossary_terms.new(abbr: "", full: "")
    assert_not term.valid?
    assert term.errors[:abbr].any? && term.errors[:full].any?

    duplicate = lessons(:pteep).glossary_terms.new(abbr: "ПУЭ", full: "Дубль")
    assert_not duplicate.valid?
    assert duplicate.errors[:abbr].any?
  end

  test "a mark is defined once per profession — another article of the same map may not redefine it" do
    duplicate = lessons(:gruppy_dopuska).glossary_terms.new(abbr: "ПУЭ", full: "Ещё раз")
    assert_not duplicate.valid?
    assert_match lessons(:pteep).title, duplicate.errors.full_messages.to_sentence

    elsewhere = lessons(:svarka_intro).glossary_terms.new(abbr: "ПУЭ", full: "В другой профессии — можно")
    assert elsewhere.valid?
  end

  test "script is derived from the mark, the anchor is a safe id" do
    assert_equal "ru", glossary_terms(:pue).script
    assert_equal "int", glossary_terms(:rcd).script
    assert_equal "ru", glossary_terms(:vvg).script, "a mixed mark with a Latin tail stays русскоязычное"
    assert_equal "МИГ-МАГ", GlossaryTerm.new(abbr: "МИГ/МАГ").anchor
  end

  test "a profession's dictionary is its published lessons' terms, Cyrillic first then alphabetical" do
    terms = GlossaryTerm.for_path(paths(:electrician)).to_a
    assert_equal [ "ВВГнг(А)-LS", "ПУЭ", "УЗО", "ЭДС", "PE", "RCD" ], terms.map(&:abbr)
    assert_includes terms, glossary_terms(:pue)
    assert_not_includes terms, glossary_terms(:naks)
    assert_empty GlossaryTerm.for_path(paths(:draft_path)), "a draft profession's terms never surface"
    assert paths(:electrician).has_glossary?
    assert_not paths(:draft_path).has_glossary?
  end

  test "by_path groups the site-wide dictionary in catalog order" do
    groups = GlossaryTerm.by_path
    assert_equal [ paths(:electrician), paths(:welder) ], groups.map(&:first)
    assert_equal %w[НАКС], groups.last.last.map(&:abbr)
  end
end
