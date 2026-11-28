require "test_helper"

class PathsControllerTest < ActionDispatch::IntegrationTest
  test "index returns success" do
    get paths_path
    assert_response :success
  end

  test "index shows only published paths" do
    get paths_path
    assert_match paths(:electrician).title, response.body
    assert_match paths(:welder).title, response.body
    assert_no_match(/Черновик/, response.body)
  end

  test "index lists the wanted professions as plain copy, not paths" do
    get paths_path
    # The vacancy board is ru.yml, not the DB — an empty Path would be admin
    # noise, and a DB-driven list only shows whatever stubs happen to exist.
    wanted = I18n.t("paths.soon_wanted")
    assert_equal wanted.size, css_select(".catalog-soon__slot").size
    wanted.each { |title| assert_match title, response.body }
    assert_no_match %r{catalog-soon__slot[^>]*href}, response.body, "slots are not links"
  end

  test "index catalog shows only paths with content" do
    get paths_path
    # Every card links somewhere real: no empty stubs reach the grid.
    assert_equal Path.published.localized.count, css_select(".catalog-grid .path-card").size
  end

  test "index puts hobby paths on their own shelf below the catalog" do
    get paths_path
    assert_select ".catalog-hobby", count: 0

    paths(:welder).update!(field: "hobby")
    get paths_path
    assert_select "#catalog .path-card", count: Path.published.localized.industrial.count
    assert_select ".catalog-hobby .path-card", count: 1
    assert_select ".catalog-hobby", text: /#{paths(:welder).title}/
    assert_operator response.body.index("catalog-hobby"), :<, response.body.index("catalog-soon"),
      "live maps come before the vacancy board"
  end

  test "index leaves out an unlisted profession, whose hub stays reachable with a notice" do
    paths(:welder).update!(listed: false)

    get paths_path
    assert_select ".path-card", text: /#{paths(:welder).title}/, count: 0
    assert_select ".path-card", text: /#{paths(:electrician).title}/

    get path_path(paths(:welder))
    assert_response :success
    assert_select ".hub .callout a[href=?]", path_path(paths(:electrician))
  end

  test "index invites a co-author with a single call" do
    get paths_path
    # One CTA button, never several competing ones. The quiet "весь список"
    # link next to it is navigation to the full wanted board, not a second call.
    assert_select ".catalog-soon .btn", count: 1
    assert_select ".catalog-soon .btn[href=?]", contribute_path
    assert_select ".catalog-soon a.link-quiet[href=?]", contribute_path(anchor: "wanted")
  end

  test "index opens with one call to choose a profession" do
    get paths_path
    assert_select "h1.hero__title[aria-label=?]", I18n.t("paths.hero.title_html").gsub("&nbsp;", " ")
    assert_select "h1.hero__title .typed__char", I18n.t("paths.hero.title_html").gsub("&nbsp;", "_").delete(" ").size
    assert_select ".hero__subtitle del.pencil", text: I18n.t("paths.hero.struck")
    assert_select ".hero__subtitle ins.pencil__fix", text: I18n.t("paths.hero.fix")
    assert_select ".hero__actions a.hero__fix[href=?]", contribute_path
    assert_select ".plant__done a.plant__placard[href=?]", contribute_path
    assert_select ".bp-stamp a[href=?]", changes_path, text: /#{LessonRevision.in_catalog.count}/
    assert_select ".hero__actions a", count: 2
    assert_select ".hero__actions a.hero__cta[href='#catalog']", text: /#{I18n.t("paths.hero.start")}/
    assert_select "#catalog"
  end

  test "index draws the sheet and hangs the professions on it as callouts" do
    get paths_path
    assert_select ".blueprint svg.blueprint__art[aria-label]", 2, "one sheet for phones, one for wide screens"
    assert_select ".blueprint__art--tall a.bp-callout[data-chip=power][href=?]", path_path(paths(:electrician)), text: /#{paths(:electrician).title}/
    assert_select ".blueprint__art--tall a.bp-callout", 1, "a profession without a place on the drawing lives in the catalog only"
    assert_select ".blueprint__art--tall [role=button][data-step]", 5, "the breakers, the valve and the start button are the controls"
    assert_select ".blueprint__art--wide [role=button][data-step]", 5
    assert_select ".blueprint[data-controller=plant] .plant__status", text: /#{I18n.t("paths.plant.running")}/
    assert_select ".plant__lesson[hidden][data-slot=power][href=?]", path_path(paths(:electrician))
    assert_select ".path-card .path-card__poster .scene--poster svg", 1
    assert_select ".path-card__poster--emblem", minimum: 1

    ids = css_select("[id]").map { |node| node["id"] }
    assert_equal ids.uniq, ids
  end

  test "index features the most-used calculators below the catalog" do
    get paths_path
    Calculator.featured.each do |calculator|
      assert_select ".home-calculators .calc-row[href=?]", calculator_path(calculator)
    end
    assert_operator response.body.index("catalog-grid"), :<, response.body.index("home-calculators")
  end

  test "show names every curator — a grant is a public role, not an opt-in" do
    users(:editor).update!(headline: "Инженер-электрик, 12 лет")
    get path_path(paths(:electrician))
    assert_select ".hub-people__line--lead", text: /#{I18n.t("paths.curated_by", count: 1)} #{users(:editor).name}/
    assert_match "Инженер-электрик, 12 лет", response.body

    get path_path(paths(:welder))
    assert_no_match I18n.t("paths.curated_by", count: 1), response.body
  end

  test "show names the author when nobody curates, and not twice when the author curates" do
    paths(:welder).update!(author: users(:member))
    get path_path(paths(:welder))
    assert_select ".hub-people__line--lead", text: /#{I18n.t("paths.authored_by")} #{users(:member).name}/

    paths(:electrician).update!(author: users(:editor))
    get path_path(paths(:electrician))
    assert_no_match I18n.t("paths.authored_by"), response.body
  end

  test "index shows only paths in the current locale" do
    Path.create!(title: "English Electrician", slug: "english-electrician",
                 description: "US market path", locale: "en", position: 9, status: "published")

    get paths_path
    assert_no_match(/English Electrician/, response.body)
  end

  test "a language with no maps yet says so and hands over the Russian catalog" do
    get paths_path(locale: :en)
    assert_response :success
    assert_select ".catalog-grid", false
    assert_select ".catalog-empty a.btn[href=?]", root_path(locale: :ru), text: I18n.t("paths.empty_locale_cta", locale: :en)
    assert_match I18n.t("paths.empty_locale_html", locale: :en), response.body
  end

  test "index shows a focus banner to a learner mid-path" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get paths_path
    assert_match "focus-banner", response.body
    assert_match paths(:electrician).title, response.body
  end

  test "index shows no focus banner to visitors" do
    get paths_path
    assert_no_match(/focus-banner/, response.body)
  end

  test "show returns success for published path" do
    get path_path(paths(:electrician))
    assert_response :success
    assert_match paths(:electrician).title, response.body
  end

  test "show returns 404 for draft path" do
    get path_path(slug: paths(:draft_path).slug)
    assert_response :not_found
  end

  test "show returns 404 for unknown slug" do
    get path_path(slug: "nonexistent")
    assert_response :not_found
  end

  test "show renders the maturity gauge at the computed stage" do
    get path_path(paths(:electrician))
    assert_select ".maturity--stage-3 .maturity__gauge"
    assert_match I18n.t("paths.maturity.stages.s3"), response.body
  end

  test "show renders the verified stage signed with the curator's name and date" do
    paths(:electrician).verify!(users(:editor))
    get path_path(paths(:electrician))
    assert_select ".maturity--stage-4"
    assert_match I18n.t("paths.maturity.stages.s4"), response.body
    assert_match I18n.t("paths.maturity.crit_verified_by", name: users(:editor).name, date: I18n.l(Date.current)), response.body
  end

  test "maturity popover offers the expert mark only to a granted editor" do
    get path_path(paths(:electrician))
    assert_no_match I18n.t("paths.maturity.verify"), response.body

    sign_in_as users(:editor)
    get path_path(paths(:electrician))
    assert_match I18n.t("paths.maturity.verify"), response.body
  end

  test "show is the hub overview: tabs to theory, practice and the reference shelf" do
    get path_path(paths(:electrician))
    assert_select ".hub-tabs__link[aria-current=page][href=?]", path_path(paths(:electrician))
    assert_select ".hub-tabs__link[href=?]", path_theory_path(paths(:electrician))
    assert_select ".hub-tabs__link[href=?]", path_practice_path(paths(:electrician))
    assert_select ".hub-tabs__link[href=?]", path_glossary_path(paths(:electrician))
    assert_select ".hub-tabs__link[href=?]", path_library_path(paths(:electrician))
    assert_match I18n.t("paths.hub.improve_title"), response.body
  end

  test "show credits accepted contributors by name, not by score" do
    get path_path(paths(:electrician))
    assert_match I18n.t("paths.hub.contributors", count: 1), response.body
    assert_select "#path-people .people-list__row", text: /Мария Сидорова/
    assert_select "#path-people a.people-list__name[href=?]", profile_path("expert"), text: "Эксперт"
    assert_select ".hub-people__line--lead", text: /Карту ведёт Эксперт/

    Editorship.create!(user: users(:admin), path: paths(:electrician))
    get path_path(paths(:electrician))
    assert_select ".hub-people__line--lead", text: /Карту ведут Админ и Эксперт/

    get path_path(paths(:welder))
    assert_select ".hub-contributors", false
  end

  test "the people popover shows at most #{Path::Contributors::SHOWN} contributors and counts the rest" do
    25.times do |i|
      LessonSuggestion.create!(lesson: lessons(:pteep), body_markdown: "правка #{i}", section: "body",
                               author_name: "Гость #{i}", status: "approved")
    end

    get path_path(paths(:electrician))
    assert_match I18n.t("paths.hub.contributors", count: 26), response.body
    assert_select "#path-people .people-list__row", count: Path::Contributors::SHOWN + 1 # + the curator's row
    assert_select ".hub-popover__more", text: "и ещё 6 человек"
  end

  test "show renders the landing slots an author filled, then the chapter outline" do
    get path_path(paths(:electrician))
    assert_select ".landing__prose", false, "an empty landing renders no story"
    assert_select ".outline__item", 3
    assert_select "a.outline__title[href=?]", course_path(courses(:el_basics))
    assert_select ".outline__item--soon", text: /#{courses(:el_relay_soon).title}/
    assert_select ".outline__all a[href=?]", path_theory_path(paths(:electrician))
    assert_select ".course-cards", false, "the cards live on the theory tab"

    paths(:electrician).update!(about: "Электрик монтирует **и** обслуживает.", highlights_text: "Читает схемы",
                                pros_text: "Востребован", cons_text: "Ответственность", history: "1882 — Эдисон.",
                                faq: "### Сколько учиться?\nГод.")
    get path_path(paths(:electrician))
    assert_select ".landing__prose strong", text: "и"
    assert_select ".landing__highlight", text: /Читает схемы/
    assert_select ".landing__points--pro li", text: /Востребован/
    assert_select ".landing__points--con li", text: /Ответственность/
    assert_select ".faq-list .faq-item__question", text: /Сколько учиться\?/
    assert_select ".faq-item__answer", text: /Год\./
    assert_operator response.body.index("landing__prose"), :<, response.body.index("outline__list"), "the story comes before the outline"
  end

  test "a long story shows its first paragraph and folds the rest" do
    paths(:electrician).update!(about: "Первый абзац.\r\n\r\nВторой абзац.") # a textarea submits CRLF
    get path_path(paths(:electrician))
    assert_select ".landing__body > .landing__prose", text: /Первый абзац/
    assert_select "details.landing__more .landing__prose", text: /Второй абзац/
  end

  test "a highlight with a bold lead becomes a titled tile" do
    paths(:electrician).update!(highlights_text: "**Читает схемы:** по ГОСТ\nПросто строка")
    get path_path(paths(:electrician))
    assert_select ".landing__highlight .landing__tile-title", text: "Читает схемы"
    assert_select ".landing__highlight .landing__tile-text", text: "по ГОСТ"
    assert_select ".landing__highlight .landing__tile-text", text: "Просто строка"
  end

  test "a profession with a scene partial draws it; one without draws none" do
    get path_path(paths(:electrician))
    assert_select ".scene svg[role=img][aria-label]"
    assert_select ".scene__legend .scene__chip", 6
    assert_select ".scene__phases span", 3

    get path_path(paths(:welder))
    assert_select ".scene", false
  end

  test "the overview counts what is inside and opens a door to every tab" do
    path = paths(:electrician)
    get path_path(path)
    assert_select ".hub-stats__item", text: /#{path.inventory.lessons}/
    assert_select ".hub-tabs__link[href=?] .hub-tabs__count", path_theory_path(path), text: path.inventory.lessons.to_s
    [ path_theory_path(path), path_practice_path(path), path_library_path(path), path_glossary_path(path) ].each do |door|
      assert_select "a.door[href=?]", door
    end
    assert_select ".path__start .btn", 2, "the call to start opens and closes the page"
  end

  test "the overview carries the pitch; a tab keeps one title row that leads back to it" do
    path = paths(:electrician)

    get path_path(path)
    assert_select ".hub__description", text: path.description
    assert_select ".hub-people"

    get path_practice_path(path)
    assert_select ".hub--compact h1 a[href=?]", path_path(path), text: path.title
    assert_select ".hub__description", false
    assert_select ".hub-people", false
  end

  test "a cover becomes the page's share image and renders with its credit" do
    path = paths(:electrician)
    path.cover.attach(io: File.open(Rails.root.join("test/fixtures/files/cover.png")), filename: "cover.png", content_type: "image/png")
    path.update!(cover_credit: "Фото: тест, CC0")

    get path_path(path)
    assert_select ".landing__cover-image"
    assert_select ".landing__cover-credit", text: "Фото: тест, CC0"
    assert_select "meta[property='og:image'][content*=?]", "/rails/active_storage/"
    assert_select "meta[name='twitter:image'][content*=?]", "/rails/active_storage/"
  end

  test "show names every chapter in the outline, coming-soon stubs included, linking the published ones" do
    get path_path(paths(:electrician))
    assert_match courses(:el_basics).title, response.body
    assert_match courses(:el_pue).title, response.body
    assert_match courses(:el_relay_soon).title, response.body
    assert_match course_path(courses(:el_basics)), response.body
  end

  test "the overview offers adding notes to the map and explains it" do
    get path_path(paths(:electrician))
    assert_select "a[href=?]", new_session_path(return_to: path_path(paths(:electrician))),
      text: "Дополнить карту комментариями для коллег"
    assert_select ".map-version__why[popovertarget=map-why]", text: "Что это?"
    assert_select "#map-why[popover]", text: /Для кого/
    assert_select "#map-why[popover]", text: /Почему только одна/

    sign_in_as users(:member)
    get path_path(paths(:electrician))
    assert_select "form[action=?] button", map_path(path: "elektrik")
  end
end
