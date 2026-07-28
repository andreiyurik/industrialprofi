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

  test "index shows the hero headline" do
    get paths_path
    assert_match I18n.t("paths.hero.title_html"), response.body
  end

  test "show credits an opted-in curator with their headline" do
    users(:editor).update!(public_curator: true, headline: "Инженер-электрик, 12 лет")
    get path_path(paths(:electrician))
    assert_response :success
    assert_match I18n.t("paths.curated_by"), response.body
    assert_match "Инженер-электрик, 12 лет", response.body
  end

  test "show hides the curator credit when nobody opted in" do
    get path_path(paths(:electrician))
    assert_response :success
    assert_no_match I18n.t("paths.curated_by"), response.body
  end

  test "index shows only paths in the current locale" do
    Path.create!(title: "English Electrician", slug: "english-electrician",
                 description: "US market path", locale: "en", position: 9, status: "published")

    get paths_path
    assert_no_match(/English Electrician/, response.body)
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

  test "show renders the verified stage with its date" do
    paths(:electrician).verify!(users(:editor))
    get path_path(paths(:electrician))
    assert_select ".maturity--stage-4"
    assert_match I18n.t("paths.maturity.stages.s4"), response.body
  end

  test "maturity popover offers the expert mark only to a granted editor" do
    get path_path(paths(:electrician))
    assert_no_match I18n.t("paths.maturity.verify"), response.body

    sign_in_as users(:editor)
    get path_path(paths(:electrician))
    assert_match I18n.t("paths.maturity.verify"), response.body
  end

  test "show lists the path's courses, including coming-soon stubs" do
    get path_path(paths(:electrician))
    assert_match courses(:el_basics).title, response.body
    assert_match courses(:el_pue).title, response.body
    assert_match courses(:el_relay_soon).title, response.body
  end

  test "show links each published course to its page" do
    get path_path(paths(:electrician))
    assert_match course_path(courses(:el_basics)), response.body
  end
end
