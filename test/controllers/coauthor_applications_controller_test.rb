require "test_helper"

class CoauthorApplicationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  VALID = {
    profession: "Оператор-наладчик ЧПУ",
    background: "8 лет на фрезерных обрабатывающих центрах, 4 разряд, допуск II группа.",
    motivation: "Знаю профессию изнутри и хочу собрать честную карту."
  }.freeze

  test "requires authentication" do
    get new_coauthor_application_url
    assert_redirected_to new_session_url
  end

  test "signed-in user sees the application form" do
    sign_in_as users(:member)
    get new_coauthor_application_url
    assert_response :success
    assert_match I18n.t("coauthor_applications.title"), response.body
  end

  test "a complete application is stored as a tagged feedback and the founder is notified" do
    sign_in_as users(:member)

    assert_enqueued_emails 1 do
      assert_difference "Feedback.count", 1 do
        post coauthor_application_url, params: { coauthor_application: VALID }
      end
    end

    assert_redirected_to dashboard_url
    feedback = Feedback.newest_first.first
    assert_equal users(:member), feedback.user
    assert_match I18n.t("coauthor_applications.message.header"), feedback.body
    assert_match VALID[:profession], feedback.body
    assert_match VALID[:background], feedback.body
  end

  test "an application missing a required field is rejected" do
    sign_in_as users(:member)

    assert_no_difference "Feedback.count" do
      post coauthor_application_url, params: { coauthor_application: VALID.merge(profession: "") }
    end
    assert_response :unprocessable_entity
  end

  test "the contribute page funnels experts to the application form" do
    get contribute_url
    assert_response :success
    assert_select "a[href=?]", new_coauthor_application_path
  end
end
