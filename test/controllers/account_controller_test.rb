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

  test "rejects an unknown avatar token" do
    patch account_url, params: { user: { avatar_token: "unicorn" } }

    assert_response :unprocessable_entity
    assert_nil @user.reload.avatar_token
  end

  test "opts in as a public curator with a headline" do
    patch account_url, params: { user: { public_curator: "1", headline: "Инженер АСУ ТП, 10 лет" } }
    assert_redirected_to account_url
    @user.reload
    assert @user.public_curator?
    assert_equal "Инженер АСУ ТП, 10 лет", @user.headline
  end
end
