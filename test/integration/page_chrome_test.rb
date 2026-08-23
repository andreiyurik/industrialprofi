require "test_helper"

# The layout's own behaviour — the toast, the skip link, the sign-in page's
# cache opt-out. Each is invisible until it breaks, and none belongs to a
# single controller.
class PageChromeTest < ActionDispatch::IntegrationTest
  test "a failed action's toast looks different and interrupts a screen reader" do
    post session_path, params: { email_address: users(:member).email_address, password: "wrong" }

    assert_response :unprocessable_entity
    assert_select ".flash__inner.flash__inner--alert[role=?]", "alert"
  end

  test "a confirmation's toast stays neutral and waits its turn" do
    sign_in_as users(:member)
    delete session_path
    follow_redirect!

    assert_select ".flash__inner[role=?]", "status"
    assert_select ".flash__inner--alert", count: 0
  end

  test "sign-in page opts out of Turbo's snapshot cache" do
    get new_session_path

    assert_select "meta[name=?][content=?]", "turbo-visit-control", "reload"
  end

  test "every page carries the language globe with a menu naming each language in its own tongue" do
    get root_path
    assert_select "details.header__locale summary.header__locale-toggle"
    assert_select "#locale-menu .locale-switcher__item--current[lang=ru]", text: /Рус/
    assert_select "#locale-menu a.locale-switcher__item[lang=en][href=?]", root_path(locale: :en), text: /Eng/

    get about_path(locale: :en)
    assert_select "#locale-menu .locale-switcher__item--current[lang=en]", text: /Eng/
    # A bilingual page switches in place (same page, other prefix).
    assert_select "#locale-menu a.locale-switcher__item[lang=ru][href=?]", about_path(locale: :ru), text: /Рус/
  end

  test "every page opens with a skip link pointing at main" do
    get root_path

    assert_select "a.skip-nav[href=?]", "#main-content"
    assert_select "main#main-content"
  end
end
