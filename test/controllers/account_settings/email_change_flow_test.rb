require "test_helper"

class AccountSettings::EmailChangeFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  CODE_PATTERN = /[#{EmailChange::ALPHABET.join}]{#{EmailChange::CODE_LENGTH}}/

  setup { sign_in_as users(:member) }

  def request_code(email = "new-address@example.com")
    perform_enqueued_jobs do
      post account_email_path, params: { email_address: email }
    end
    ActionMailer::Base.deliveries.last.subject[CODE_PATTERN]
  end

  test "full flow: request a code, verify it, email address changes" do
    code = request_code
    assert_redirected_to new_account_email_verification_path

    post account_email_verification_path, params: { code: code }
    assert_redirected_to account_path

    assert_equal "new-address@example.com", users(:member).reload.email_address
  end

  test "rejects a wrong code" do
    request_code
    post account_email_verification_path, params: { code: "WRONG1" }
    assert_response :unprocessable_entity
    assert_not_equal "new-address@example.com", users(:member).reload.email_address
  end

  test "code entry is case-insensitive" do
    code = request_code
    post account_email_verification_path, params: { code: code.downcase }
    assert_redirected_to account_path
  end

  test "verification page requires a pending email change" do
    get new_account_email_verification_path
    assert_redirected_to edit_account_email_path
  end

  test "rejects an email already taken by another user" do
    post account_email_path, params: { email_address: users(:editor).email_address }
    assert_response :unprocessable_entity
  end
end
