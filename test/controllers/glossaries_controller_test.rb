require "test_helper"

class GlossariesControllerTest < ActionDispatch::IntegrationTest
  test "show renders the glossary to visitors" do
    get glossary_path
    assert_response :success
    assert_match "ПУЭ", response.body
    assert_match "Правила устройства электроустановок", response.body
  end

  test "terms group under their profession with a link to its map" do
    get glossary_path
    assert_select ".glossary-group#elektrik" do
      assert_select ".glossary-group__title", text: paths(:electrician).title
    end
    assert_match path_path(paths(:electrician)), response.body
  end

  test "a term without a resolvable lesson falls back to search" do
    # Fixture DB has none of the real curriculum slugs, so every term takes
    # the search fallback — links must never rot into 404s.
    get glossary_path
    assert_match search_path(q: "ПУЭ"), CGI.unescapeHTML(response.body)
  end

  test "show ships the live filter with its empty state" do
    get glossary_path
    assert_select "[data-controller='glossary-filter']"
    assert_select ".glossary-toolbar__input"
    assert_select ".glossary-empty[hidden]"
    # Two populated professions in fixtures (электрик + сварщик) → quick-jump
    # chips render, one per group, each with its term count.
    assert_select ".glossary-chips .glossary-chip", 2
    assert_select ".glossary-chip[href='#svarshchik']", text: /Сварщик/
  end

  test "terms split into russian and international subsections with a toggle" do
    get glossary_path
    assert_select ".glossary-scripts button", 3
    assert_select ".glossary-sub[data-script='ru'] .glossary__term", text: "ПУЭ"
    assert_select ".glossary-sub[data-script='int'] .glossary__term", text: "PE"
    # Mixed marks (ГОСТ cable codes with Latin tails) stay русскоязычные.
    assert_select ".glossary-sub[data-script='ru'] .glossary__term", text: "ВВГнг(А)-LS"
  end

  test "analog counterparts cross-link when both entries exist" do
    get glossary_path
    # УЗО ≈ RCD — both present, so the mark is an anchor link both ways.
    assert_select "#elektrik-УЗО .glossary__analog a[href='#elektrik-RCD']", text: "RCD"
    assert_select "#elektrik-RCD .glossary__analog a[href='#elektrik-УЗО']", text: "УЗО"
    # ЭДС ≈ EMF — no EMF entry, so the mark stays plain text.
    assert_select "#elektrik-ЭДС .glossary__analog", text: /EMF/
    assert_select "#elektrik-ЭДС .glossary__analog a", 0
  end

  test "entries carry shareable anchors" do
    get glossary_path
    assert_select ".glossary__entry#elektrik-ПУЭ"
  end
end
