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
    # Two populated professions in fixtures (электрик + сварщик) → chips
    # render: «Все» + one per profession, each a server-side filter link.
    assert_select ".glossary-chips .glossary-chip", 3
    assert_select ".glossary-chip[href=?]", glossary_path(path: "svarshchik"), text: /Сварщик/
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

  test "path param renders one profession's focused page" do
    get glossary_path(path: "svarshchik")
    assert_response :success
    assert_select ".glossary-group", 1
    assert_select ".glossary-group__title", text: paths(:welder).title
    # Chips still list every profession, the active one marked.
    assert_select ".glossary-chip", 3
    assert_select ".glossary-chip.is-active[href=?]", glossary_path(path: "svarshchik")
    assert_match "glossary?path=svarshchik", css_select("link[rel=canonical]").first["href"]
  end

  test "unknown or uncovered path 404s" do
    get glossary_path(path: "nonexistent")
    assert_response :not_found

    uncovered = Path.create!(title: "Геодезист", slug: "geodezist", description: "x",
                             position: 9, status: "published")
    get glossary_path(path: uncovered.slug)
    assert_response :not_found
  end

  test "sitemap lists the focused glossary pages" do
    get "/sitemap.xml"
    assert_match "/glossary</loc>", response.body
    assert_match "/glossary?path=elektrik</loc>", response.body
    assert_no_match "/glossary?path=draft-path", response.body
  end

  test "re-crawls get a render-free 304 for visitors" do
    get glossary_path
    assert_response :success
    assert response.headers["Last-Modified"].present?

    get glossary_path, headers: { "HTTP_IF_MODIFIED_SINCE" => response.headers["Last-Modified"] }
    assert_response :not_modified
  end

  test "signed-in readers always render fresh" do
    sign_in_as users(:member)
    get glossary_path, headers: { "HTTP_IF_MODIFIED_SINCE" => Time.current.httpdate }
    assert_response :success
  end

  test "entries carry shareable anchors" do
    get glossary_path
    assert_select ".glossary__entry#elektrik-ПУЭ"
  end
end
