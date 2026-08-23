require "test_helper"

class Paths::TheoriesControllerTest < ActionDispatch::IntegrationTest
  test "the theory tab lists the chapters with their cards, coming-soon stubs included" do
    get path_theory_path(paths(:electrician))
    assert_response :success
    assert_select ".hub-tabs__link[aria-current=page][href=?]", path_theory_path(paths(:electrician))
    assert_select ".course-cards .course-card", 3
    assert_match courses(:el_relay_soon).title, response.body
    assert_select ".course-card__title-link[href=?]", course_path(courses(:el_basics))
    assert_match I18n.t("paths.start_learning"), response.body
  end

  test "a learner's progress rides on the cards and the continue button" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))
    sign_in_as users(:member)

    get path_theory_path(paths(:electrician))
    assert_match I18n.t("paths.continue_learning"), response.body
    assert_match I18n.t("paths.next_up", title: lessons(:gruppy_dopuska).title), response.body
  end

  test "draft and unknown professions are not found; the wrong locale 301s" do
    get path_theory_path(paths(:draft_path))
    assert_response :not_found

    get "/en/paths/#{paths(:electrician).slug}/theory"
    assert_redirected_to "/ru/paths/#{paths(:electrician).slug}/theory"
  end
end
