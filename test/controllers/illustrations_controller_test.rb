require "test_helper"

class IllustrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:pteep)
    @lesson.update!(body: "Текст\n\n![Щит с открытой дверцей](TODO-shchit.png)\n")
  end

  test "the public queue lists every pending brief with a suggest link" do
    get illustrations_url
    assert_response :success
    assert_match "Щит с открытой дверцей", response.body
    assert_select "a[href=?]", lesson_path(@lesson)
    assert_select "a[href^=?]", new_lesson_illustration_suggestion_path(@lesson)
  end

  test "the home page nudges with the pending count" do
    get root_url(locale: :ru)
    assert_response :success
    assert_select ".focus-banner a[href=?]", illustrations_path
    assert_match I18n.t("paths.illustrations_call", count: 1), response.body
  end

  test "a reader sees the suggest link on the placeholder, an editor the fill link" do
    get lesson_url(@lesson)
    assert_select "a.attachment__suggest[href^=?]", new_lesson_illustration_suggestion_path(@lesson)
    assert_select ".lesson--fillable", count: 0

    sign_in_as users(:admin)
    get lesson_url(@lesson)
    assert_select ".lesson--fillable a.attachment__fill"
  end
end
