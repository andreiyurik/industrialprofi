require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "static pages are cacheable (so clients and crawlers skip re-fetching)" do
    get about_path
    assert_response :success
    cache_control = response.headers["Cache-Control"].to_s
    assert_includes cache_control, "max-age=3600"
    assert_includes cache_control, "private", "static pages cache privately, not in shared caches"
  end

  test "search-engine verification meta tags render only when configured" do
    site = Rails.application.config.x.site

    get about_path
    assert_select "meta[name='google-site-verification']", count: 0, message: "omitted when unset"
    assert_select "meta[name='yandex-verification']", count: 0

    site.google_site_verification = "google-abc123"
    site.yandex_verification = "yandex-def456"
    get about_path
    assert_select "meta[name='google-site-verification'][content='google-abc123']", count: 1
    assert_select "meta[name='yandex-verification'][content='yandex-def456']", count: 1
  ensure
    site.google_site_verification = nil
    site.yandex_verification = nil
  end

  test "about page renders the creator's letter" do
    get about_path
    assert_response :success
    assert_select "h1.about-letter__title", text: I18n.t("about.title")
    assert_select ".about-letter__sign-name", text: I18n.t("about.signature_name")
    assert_includes @response.body, I18n.t("about.intro1")
    # the letter's structure: section subheads + pulled-out key thoughts
    assert_select "h2.about-letter__heading", count: 4
    assert_select "p.about-letter__highlight", count: 3
    assert_includes @response.body, "экспертом мирового уровня"
  end

  test "about page links to professions and support" do
    get about_path
    assert_select ".about-letter__cta a[href=?]", paths_path
    assert_select ".about-letter__cta a[href=?]", support_us_path
  end

  test "footer exposes the about link on every page" do
    # "About the project" lives in the footer now — the header carries only the
    # "use the product" links (professions/practice/calculators).
    get root_path
    assert_select "footer.footer a[href=?]", about_path, text: I18n.t("nav.about")
  end

  test "support page still renders" do
    get support_us_path
    assert_response :success
  end

  test "privacy policy page renders all sections" do
    get privacy_path
    assert_response :success
    assert_select "h1.legal__title", text: I18n.t("privacy.title")
    assert_select "h2.legal__heading", count: 10
    # The rights section links to account settings (the data-deletion path).
    assert_select ".legal a[href=?]", account_path
  end

  test "footer links to the privacy policy on every page" do
    get root_path
    assert_select "footer a[href=?]", privacy_path, text: I18n.t("nav.privacy")
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

  test "faq page renders every question with FAQPage structured data" do
    get faq_path

    assert_response :success
    assert_select ".faq-item__question", count: I18n.t("faq.items").size
    # the honest "no certificates" answer must be there
    assert_match "аттестации НАКС выдают только аккредитованные", response.body
    assert_select "script[type='application/ld+json']", text: /FAQPage/
  end

  test "footer exposes the faq link on every page" do
    get root_path
    assert_select "footer.footer a[href=?]", faq_path, text: I18n.t("nav.faq")
  end

  test "partners page shows the invitation (not an empty roster) and the independence policy" do
    get partners_path
    assert_response :success
    assert_select "h1.partners-hero__title", text: I18n.t("partners.title")
    # No partners yet → forward-looking invitation, and NO empty tier headings.
    assert_select ".partners-invite", text: I18n.t("partners.empty_invite")
    assert_select ".partners-tier", count: 0
    # The trust firewall is stated on the page itself.
    assert_includes @response.body, I18n.t("partners.independence_title")
  end

  test "footer exposes the partners link on every page" do
    get root_path
    assert_select "footer.footer a[href=?]", partners_path, text: I18n.t("nav.partners")
  end
end
