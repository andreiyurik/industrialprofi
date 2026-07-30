require "test_helper"

# The account menu's role gating, asserted on the rendered header rather than in a
# browser — it's markup, not behaviour, so it needs no Selenium. The two surfaces
# both come from shared/_account_identity + shared/_account_links, so checking the
# page once covers both.
class AccountMenuTest < ActionDispatch::IntegrationTest
  test "an editor or admin gets the workspace link and a role mark" do
    sign_in_as users(:admin)
    get paths_path

    assert_select ".account-menu__link--work", 2, "по одной ссылке в рабочее место на каждую поверхность"
    assert_select ".account-menu__role", text: "Администратор", count: 2
  end

  test "a plain member gets neither" do
    sign_in_as users(:member)
    get paths_path

    assert_select ".account-menu__link--work", false
    assert_select ".account-menu__role", false
  end

  # A guest's sheet reuses the same row component for its orientation links, so the
  # tell is the personal menu's own parts: the trigger button and sign-out.
  test "a guest gets no personal menu" do
    get paths_path

    assert_select ".account-menu-button", false
    assert_select ".account-menu__signout", false
    assert_select ".account-menu__link--work", false
  end
end
