require "test_helper"

class Profiles::FollowsControllerTest < ActionDispatch::IntegrationTest
  setup { @map = maps(:expert_map) }

  test "requires authentication" do
    post profile_map_follow_path(@map)
    assert_redirected_to new_session_path
  end

  test "take puts the map on the dashboard, once" do
    sign_in_as users(:admin)
    assert_difference -> { @map.reload.follows_count }, 1 do
      post profile_map_follow_path(@map)
      post profile_map_follow_path(@map)
    end
    assert_redirected_to profile_map_path(@map)

    get dashboard_path
    assert_select ".dashboard-map__title", text: "Первые 30 дней на участке"
  end

  test "the author cannot take their own map" do
    sign_in_as users(:editor)
    assert_no_difference -> { MapFollow.count } do
      post profile_map_follow_path(@map)
    end
  end

  test "drop removes the follow" do
    sign_in_as users(:member)
    assert_difference -> { @map.reload.follows_count }, -1 do
      delete profile_map_follow_path(@map)
    end
  end
end
