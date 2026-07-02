require "test_helper"

class BusinessInquiriesControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  VALID = {
    organization: "УЦ «Энергетик»",
    contact: "director@example.com",
    message: "Готовим электромонтёров, 60 человек в год. Нужны групповые отчёты."
  }.freeze

  test "the page is public" do
    get business_url
    assert_response :success
    assert_match I18n.t("business_inquiries.title"), response.body
  end

  test "a complete inquiry is stored as a guest feedback and the founder is notified" do
    assert_emails 1 do
      assert_difference "Feedback.count", 1 do
        perform_enqueued_jobs do
          post business_url, params: { business_inquiry: VALID }
        end
      end
    end

    assert_redirected_to business_url
    feedback = Feedback.newest_first.first
    assert_nil feedback.user
    assert_match I18n.t("business_inquiries.message.header"), feedback.body
    assert_match VALID[:organization], feedback.body
    assert_match VALID[:contact], feedback.body
  end

  test "a signed-in sender is attached to the inquiry" do
    sign_in_as users(:member)

    post business_url, params: { business_inquiry: VALID }
    assert_equal users(:member), Feedback.newest_first.first.user
  end

  test "an inquiry missing a required field is rejected" do
    assert_no_difference "Feedback.count" do
      post business_url, params: { business_inquiry: VALID.merge(contact: "") }
    end
    assert_response :unprocessable_entity
  end

  test "the honeypot swallows bots" do
    assert_no_difference "Feedback.count" do
      post business_url, params: { business_inquiry: VALID, company: "SpamCo" }
    end
    assert_redirected_to business_url
  end

  test "the footer links to the business page" do
    get root_url
    assert_select "a[href=?]", business_path
  end
end
