require "application_system_test_case"

# The personal menu exists on two surfaces — the hamburger sheet on a phone and the
# anchored popover on a wide screen. They render one shared partial, and this holds
# them to it. One sign-in, both surfaces: signing in per test made the suite flaky
# for no extra coverage. Role gating is cheaper to assert without a browser, in
# test/controllers/account_menu_test.rb.
class AccountMenuTest < ApplicationSystemTestCase
  test "the sheet and the popover offer the same account items" do
    sign_in_as users(:admin)

    resize(1280)
    visit paths_path
    find(".account-menu-button").click
    assert_selector "#account-menu:popover-open"
    popover = all("#account-menu .account-menu__link").map { it.text.strip }
    assert_selector "#account-menu .account-menu__role", text: "Администратор"

    resize(390)
    visit paths_path
    find(".header__menu-toggle").click
    assert_selector ".header__menu[open]"
    sheet = all(".header__menu-account .account-menu__link").map { it.text.strip }
    assert_selector ".header__menu-panel .account-menu__role", text: "Администратор"

    assert_includes popover, "Моё обучение"
    assert_equal popover, sheet, "меню аккаунта разъехались между поповером и ящиком"
  end

  private
    def resize(width)
      page.driver.browser.manage.window.resize_to(width, 900)
    end
end
