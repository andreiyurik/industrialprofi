require "test_helper"

class ChangesControllerTest < ActionDispatch::IntegrationTest
  test "lists accepted revisions across published professions with their authors" do
    lessons(:pteep).revise!(section: "body", html: "<p>Версия один</p>",
                            editor_name: "Иван", edit_reason: "уточнил пункт", source: "suggestion")
    lessons(:draft_lesson).revise!(section: "body", html: "<p>Черновик</p>",
                                   editor_name: "Скрытый", edit_reason: nil, source: "admin")

    get changes_url
    assert_response :success
    assert_match "Иван", response.body
    assert_match "уточнил пункт", response.body
    assert_match lessons(:pteep).title, response.body
    assert_no_match "Скрытый", response.body
  end

  test "an empty history says so" do
    get changes_url
    assert_response :success
    assert_match I18n.t("changes.empty"), response.body
  end
end
