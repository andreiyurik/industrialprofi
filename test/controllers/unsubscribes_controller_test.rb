require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:member)
  end

  test "link from the email unsubscribes without login" do
    get unsubscribe_url(@user.generate_token_for(:email_unsubscribe))

    assert_response :success
    assert_not @user.reload.reminder_emails?
  end

  test "RFC 8058 one-click POST unsubscribes" do
    post unsubscribe_url(@user.generate_token_for(:email_unsubscribe))

    assert_response :ok
    assert_not @user.reload.reminder_emails?
  end

  test "a bad token renders the friendly failure page" do
    get unsubscribe_url("garbage")

    assert_response :success
    assert @user.reload.reminder_emails?
  end

  test "kind=suggestions stops suggestion emails and keeps reminders" do
    get unsubscribe_url(@user.generate_token_for(:email_unsubscribe), kind: "suggestions")

    assert_response :success
    assert_not @user.reload.suggestion_emails?
    assert @user.reminder_emails?
  end

  test "an unknown kind falls back to reminders" do
    get unsubscribe_url(@user.generate_token_for(:email_unsubscribe), kind: "bogus")

    assert_not @user.reload.reminder_emails?
    assert @user.suggestion_emails?
  end
end
