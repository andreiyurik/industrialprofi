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

  test "index invites a co-author with a single call" do
    get paths_path
    # One CTA button, never several competing ones. The quiet "весь список"
    # link next to it is navigation to the full wanted board, not a second call.
    assert_select ".catalog-soon .btn", count: 1
    assert_select ".catalog-soon .btn[href=?]", contribute_path
    assert_select ".catalog-soon a.link-quiet[href=?]", contribute_path(anchor: "wanted")
  end

  test "index shows the hero headline and the three doors" do
    get paths_path
    assert_match I18n.t("paths.hero.title_html"), response.body
    assert_select ".hero__actions a.btn--reversed[href='#catalog']", text: /#{I18n.t("paths.hero.theory")}/
    assert_select ".hero__actions a.btn[href=?]", projects_path, text: /#{I18n.t("paths.hero.practice")}/
    assert_select ".hero__actions a.btn[href=?]", contribute_path, text: /#{I18n.t("paths.hero.improve")}/
    assert_select "#catalog"
  end

  test "show names every curator — a grant is a public role, not an opt-in" do
    users(:editor).update!(headline: "Инженер-электрик, 12 лет")
    get path_path(paths(:electrician))
    assert_select ".hub-people__line--lead", text: /#{I18n.t("paths.curated_by")} #{users(:editor).name}/
    assert_match "Инженер-электрик, 12 лет", response.body

    get path_path(paths(:welder))
    assert_no_match I18n.t("paths.curated_by"), response.body
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
    assert_select "#path-contributors li", text: "Мария Сидорова"

    get path_path(paths(:welder))
    assert_select ".hub-contributors", false
  end

  test "show renders the landing slots an author filled, then the chapter outline" do
    get path_path(paths(:electrician))
    assert_select ".landing", false, "an empty landing renders nothing"
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

  test "the header says the author's tagline when there is one, else the catalog sentence, on every tab" do
    get path_theory_path(paths(:electrician))
    assert_select ".hub__description", text: paths(:electrician).description

    paths(:electrician).update!(tagline: "Ток идёт туда, куда ты скажешь.")
    get path_path(paths(:electrician))
    assert_select ".hub__description", text: "Ток идёт туда, куда ты скажешь."
    get path_practice_path(paths(:electrician))
    assert_select ".hub__description", text: "Ток идёт туда, куда ты скажешь."
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
end
