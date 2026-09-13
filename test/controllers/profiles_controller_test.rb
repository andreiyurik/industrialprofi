require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "a profile is public, noindex, and shows the map and the role" do
    get profile_path("expert")

    assert_response :success
    assert_select "meta[name=robots][content='noindex, follow']"
    assert_select "h1", text: /Эксперт/
    assert_select ".profile__role", text: "Эксперт"
    assert_select ".profile__headline", text: /Инженер АСУ ТП, 15 лет/
    assert_select "a[href=?]", profile_map_path(maps(:expert_map)), text: /Первые 30 дней/
    assert_select ".profile__line", text: /Курирует:.*Электрик/m
    assert_select ".profile__line", text: /Черновик/, count: 0
  end

  test "accepted edits are listed with a link to the lesson's history" do
    lesson_suggestions(:approved_suggestion).update_columns(user_id: users(:editor).id)
    get profile_path("expert")
    assert_select "a[href=?]", lesson_revisions_path(lessons(:pteep))
  end

  test "progress is private unless the person opts in" do
    users(:editor).lesson_completions.create!(lesson: lessons(:pteep))
    get profile_path("expert")
    assert_select ".heatmap", count: 0

    users(:editor).update!(show_progress: true)
    get profile_path("expert")
    assert_select ".heatmap"
    assert_select ".profile-path__title", text: "Электрик"
  end

  test "no handle, unknown handle or a suspended account is 404" do
    get profile_path("nobody")
    assert_response :not_found

    users(:editor).suspend!
    get profile_path("expert")
    assert_response :not_found
  end
end
