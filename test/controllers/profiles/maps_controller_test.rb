require "test_helper"

class Profiles::MapsControllerTest < ActionDispatch::IntegrationTest
  setup { @map = maps(:expert_map) }

  test "a guest reads the map: lessons, links with nofollow, the notice, a sign-in call" do
    get profile_map_path(@map)

    assert_response :success
    assert_select "meta[name=robots][content='noindex, follow']"
    assert_select "meta[property='og:title'][content*='Первые 30 дней']"
    assert_select "h1", "Первые 30 дней на участке"
    assert_select "a[href=?]", lesson_path(lessons(:pteep)), text: /ПТЭЭП/
    assert_select ".curriculum__header-title", text: "Основы и электробезопасность"
    assert_select ".curriculum__extra-note", text: "Только главы 1.1–1.4"
    assert_select ".curriculum__extra a[href='https://example.com/reglament.pdf'][rel='nofollow ugc noopener']", text: /Регламент участка/
    assert_select ".curriculum__extra-note", text: "Разделы 2 и 4"
    assert_select ".resource-block__title", text: "От автора", count: 0 # no loose links → no block
    assert_select "a[href=?]", new_session_path(return_to: profile_map_path(@map)), text: "Взять себе"
    assert_select "a[href=?]", new_session_path(return_to: path_path(paths(:electrician))),
      text: "Дополнить карту комментариями для коллег"
    assert_select ".map-page__notice"
    assert_select "a[href=?]", profile_path("expert")
  end

  test "loose links get the «От автора» panel" do
    @map.items.create!(title: "Общая", url: "https://example.com/all")
    get profile_map_path(@map)
    assert_select ".resource-block__title", text: "От автора"
    assert_select ".resource-block a[href='https://example.com/all']", text: "Общая"
  end

  test "signing in from a map lands back on it, and an off-site return is ignored" do
    get new_session_path(return_to: profile_map_path(@map))
    post session_path, params: { email_address: users(:admin).email_address, password: "password" }
    assert_redirected_to profile_map_path(@map)

    delete session_path
    get new_session_path(return_to: "//evil.example.com")
    post session_path, params: { email_address: users(:admin).email_address, password: "password" }
    assert_redirected_to dashboard_path
  end

  test "reading a shared map does not touch the session" do
    get profile_map_path(@map)
    assert_nil response.headers["Set-Cookie"], "a guest read must stay cacheable"
  end

  test "a follower sees their ticks and the drop button" do
    sign_in_as users(:member)
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))
    get profile_map_path(@map)

    assert_select ".curriculum__lesson--done", count: 1
    assert_select ".progress__label", text: /1.*2/
    assert_select "form[action=?] button", profile_map_follow_path(@map), text: "Убрать"
    assert_select "form[action=?] button", map_path(path: "elektrik"), text: /Дополнить карту комментариями для коллег/
  end

  test "the author gets the edit button and no build-your-own call" do
    sign_in_as users(:editor)
    get profile_map_path(@map)
    assert_select "a[href=?]", edit_map_path
    assert_select ".map-page__build", count: 0
  end

  test "a map of an account without a handle or a suspended one is 404" do
    get profile_map_path("ivan")
    assert_response :not_found

    users(:editor).suspend!
    get profile_map_path(@map)
    assert_response :not_found
  end
end
