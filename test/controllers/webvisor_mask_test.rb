require "test_helper"

class WebvisorMaskTest < ActionDispatch::IntegrationTest
  test "identity and admin pages are masked from Webvisor" do
    sign_in_as users(:admin)

    get paths_path
    assert_select ".account-menu-button.ym-hide-content"
    assert_select "main.ym-hide-content", false

    get account_path
    assert_select "main.ym-hide-content"

    get admin_root_path
    assert_select "main.ym-hide-content"
  end
end
