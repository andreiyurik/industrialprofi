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

  test "picks a preset avatar and returns to initials" do
    patch account_url, params: { user: { avatar_token: "wrench" } }
    assert_redirected_to account_url
    assert_equal "wrench", @user.reload.avatar_token

    patch account_url, params: { user: { avatar_token: "" } }
    assert_nil @user.reload.avatar_token.presence
  end

  test "sets a profile address and the progress toggle" do
    patch account_url, params: { user: { handle: "Ivan-P", show_progress: "1" } }
    assert_redirected_to account_url
    assert_equal "ivan-p", @user.reload.handle
    assert @user.show_progress?

    get account_url
    assert_select "a[href=?]", profile_path("ivan-p")
  end

  test "rejects a taken or malformed address" do
    patch account_url, params: { user: { handle: "expert" } }
    assert_response :unprocessable_entity

    patch account_url, params: { user: { handle: "Иван" } }
    assert_response :unprocessable_entity
    assert_nil @user.reload.handle
  end

  test "rejects an unknown avatar token" do
    patch account_url, params: { user: { avatar_token: "unicorn" } }

    assert_response :unprocessable_entity
    assert_nil @user.reload.avatar_token
  end

  test "saves the curator headline" do
    patch account_url, params: { user: { headline: "Инженер АСУ ТП, 10 лет" } }
    assert_redirected_to account_url
    assert_equal "Инженер АСУ ТП, 10 лет", @user.reload.headline
  end
end
