require "test_helper"

class Admin::GuideControllerTest < ActionDispatch::IntegrationTest
  test "without auth it redirects to sign-in" do
    get admin_guide_path
    assert_redirected_to new_session_path
  end

  test "a regular member cannot see the guide" do
    sign_in_as users(:member)
    get admin_guide_path
    assert_redirected_to root_path
  end

  test "an editor can read the guide, which renders real badges and callouts" do
    sign_in_as users(:editor)
    get admin_guide_path
    assert_response :success
    assert_select ".badge--norm" # a resource-type badge
    assert_select ".badge--lang" # the language marker
    assert_select ".callout--check" # a live-rendered callout
    assert_match I18n.t("lessons.resource_kinds.doc"), response.body
  end
end
