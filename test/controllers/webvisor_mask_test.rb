require "test_helper"

class WebvisorMaskTest < ActionDispatch::IntegrationTest
  setup do
    @site = Rails.application.config.x.site
    @original_metrika_id = @site.metrika_id
    @site.metrika_id = "12345"
  end

  teardown { @site.metrika_id = @original_metrika_id }

  test "public teaching pages are recorded, the account menu is not" do
    sign_in_as users(:admin)
    get paths_path

    assert_select "main.ym-hide-content", false
    assert_select ".account-menu-button.ym-hide-content"
    assert_select ".account-menu__header:not(.ym-hide-content)", false
  end

  test "personal, admin and form pages are masked by default" do
    sign_in_as users(:admin)

    [ account_path, admin_root_path, journal_entries_path, profile_path("expert") ].each do |path|
      get path
      assert_select "main.ym-hide-content", 1, path
    end
  end

  test "token pages never load Metrika" do
    get edit_password_path(users(:member).password_reset_token)
    assert_no_match "mc.yandex.ru", response.body

    get unsubscribe_path(users(:member).generate_token_for(:email_unsubscribe))
    assert_no_match "mc.yandex.ru", response.body

    get paths_path
    assert_match "mc.yandex.ru", response.body
  end
end
