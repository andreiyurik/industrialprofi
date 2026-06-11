require "test_helper"

class AccountControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:member)
    sign_in_as @user
  end

  test "updates the name" do
    patch account_url, params: { user: { name: "Новое имя" } }

    assert_redirected_to account_url
    assert_equal "Новое имя", @user.reload.name
  end

  test "turns reminder emails off and back on" do
    patch account_url, params: { user: { reminder_emails: "0" } }
    assert_redirected_to account_url
    assert_not @user.reload.reminder_emails?

    patch account_url, params: { user: { reminder_emails: "1" } }
    assert @user.reload.reminder_emails?
  end
end
