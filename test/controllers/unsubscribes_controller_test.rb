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
end
