require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "about page renders the creator's letter" do
    get about_path
    assert_response :success
    assert_select "h1.about-letter__title", text: I18n.t("about.title")
    assert_select ".about-letter__sign-name", text: I18n.t("about.signature_name")
    assert_includes @response.body, I18n.t("about.p1")
  end

  test "about page links to professions and support" do
    get about_path
    assert_select ".about-letter__cta a[href=?]", paths_path
    assert_select ".about-letter__cta a[href=?]", support_us_path
  end

  test "header exposes the about link on every page" do
    get root_path
    assert_select "header.header a[href=?]", about_path, text: I18n.t("nav.about")
  end

  test "support page still renders" do
    get support_us_path
    assert_response :success
  end

  test "roadmap page renders status groups and items" do
    get roadmap_path
    assert_response :success
    assert_select "h1.roadmap__title", text: I18n.t("roadmap.title")
    # Five status groups, each with a badge heading
    assert_select ".roadmap-group", 5
    assert_select ".roadmap-group__title .badge", text: I18n.t("roadmap.groups.done.title")
    assert_select ".roadmap-group__title .badge", text: I18n.t("roadmap.groups.not_now.title")
    # Items render from the nested i18n structure
    first_done = I18n.t("roadmap.groups.done.items").first[:t]
    assert_select ".roadmap-item__title", text: first_done
  end

  test "footer exposes the roadmap link on every page" do
    get root_path
    assert_select "footer.footer a[href=?]", roadmap_path, text: I18n.t("nav.roadmap")
  end
end
