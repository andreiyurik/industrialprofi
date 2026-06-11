require "test_helper"

class SignupsFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  CODE_PATTERN = /[#{Signup::ALPHABET.join}]{#{Signup::CODE_LENGTH}}\z/

  def request_code(email = "new@example.com")
    perform_enqueued_jobs do
      post signup_path, params: { email_address: email }
    end
    ActionMailer::Base.deliveries.last.subject[CODE_PATTERN]
  end

  test "full flow: email, code, profile — signed in with a welcome letter" do
    code = request_code
    assert_redirected_to new_signup_verification_path

    post signup_verification_path, params: { code: code }
    assert_redirected_to new_signup_completion_path

    assert_difference -> { User.count }, 1 do
      post signup_completion_path, params: { user: {
        name: "Новый Пользователь", password: "password123", password_confirmation: "password123"
      } }
    end
    assert_redirected_to dashboard_path

    follow_redirect!
    assert_response :success
    assert_match "welcome-letter__title", response.body

    get dashboard_path
    assert_no_match(/welcome-letter__title/, response.body)

    assert_equal "new@example.com", User.order(:created_at).last.email_address
  end

  test "rejects an invalid email" do
    post signup_path, params: { email_address: "not-an-email" }
    assert_response :unprocessable_entity
  end

  test "redirects an already registered email to sign-in" do
    assert_no_enqueued_emails do
      post signup_path, params: { email_address: users(:member).email_address }
    end
    assert_redirected_to new_session_path
  end

  test "rejects a wrong code" do
    request_code
    post signup_verification_path, params: { code: "WRONG1" }
    assert_response :unprocessable_entity
  end

  test "code entry is case-insensitive" do
    code = request_code
    post signup_verification_path, params: { code: code.downcase }
    assert_redirected_to new_signup_completion_path
  end

  test "completion is gated behind verification" do
    get new_signup_completion_path
    assert_redirected_to new_signup_path

    request_code
    get new_signup_completion_path
    assert_redirected_to new_signup_verification_path

    post signup_completion_path, params: { user: { name: "Хакер", password: "password123", password_confirmation: "password123" } }
    assert_redirected_to new_signup_verification_path
  end

  test "verification page requires a pending signup" do
    get new_signup_verification_path
    assert_redirected_to new_signup_path
  end

  test "resend issues a fresh code that works" do
    request_code
    new_code = request_code

    post signup_verification_path, params: { code: new_code }
    assert_redirected_to new_signup_completion_path
  end

  test "completion with invalid profile re-renders" do
    code = request_code
    post signup_verification_path, params: { code: code }

    assert_no_difference -> { User.count } do
      post signup_completion_path, params: { user: { name: "", password: "short", password_confirmation: "short" } }
    end
    assert_response :unprocessable_entity
  end
end
