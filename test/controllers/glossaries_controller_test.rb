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

  test "every term leads to the lesson that defines it; draft professions stay out" do
    get glossary_path
    assert_select ".glossary__entry#elektrik-ПУЭ .glossary__action a[href=?]", lesson_path(lessons(:pteep))
    assert_no_match "ЧРН", response.body
  end

  test "show ships the live filter with its empty state" do
    get glossary_path
    assert_select "[data-controller='glossary-filter']"
    assert_select ".glossary-toolbar__input"
    assert_select ".glossary-empty[hidden]"
    # Two populated professions in fixtures (электрик + сварщик) → one chip
    # per profession, each leading into that profession's reference shelf.
    assert_select ".glossary-chips .glossary-chip", 2
    assert_select ".glossary-chip[href=?]", path_glossary_path(paths(:welder)), text: /Сварщик/
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

  test "path param 301s to the profession's hub dictionary" do
    get glossary_path(path: "svarshchik")
    assert_redirected_to path_glossary_path(paths(:welder))
    assert_response :moved_permanently
  end

  test "unknown or uncovered path 404s" do
    get glossary_path(path: "nonexistent")
    assert_response :not_found

    uncovered = Path.create!(title: "Геодезист", slug: "geodezist", description: "x",
                             position: 9, status: "published")
    get glossary_path(path: uncovered.slug)
    assert_response :not_found
  end

  test "sitemap lists the hub dictionaries, not the old focused pages" do
    get "/sitemap.xml"
    assert_match "/glossary</loc>", response.body
    assert_match "/paths/elektrik/glossary</loc>", response.body
    assert_no_match "/glossary?path=", response.body
    assert_no_match "/paths/draft-path/glossary", response.body
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
