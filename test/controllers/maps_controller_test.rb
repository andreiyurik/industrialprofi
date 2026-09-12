require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    post map_path(path: "elektrik")
    assert_redirected_to new_session_path
  end

  test "one click makes the profession the member's version, storing nothing but the link to it" do
    sign_in_as users(:member)

    assert_difference -> { Map.count }, 1 do
      assert_no_difference -> { MapItem.count }, "an overlay copies nothing" do
        post map_path(path: "elektrik")
      end
    end
    assert_redirected_to edit_map_path

    map = users(:member).reload.map
    assert_equal "Электрик — версия Иван", map.title
    assert_equal paths(:electrician), map.path
    assert_equal paths(:electrician).lessons.joins(:course).merge(Course.published).count, map.lessons.size
    assert_not_includes map.lessons, lessons(:draft_lesson)
    assert_equal "ivan", users(:member).handle

    follow_redirect!
    assert_select "details.map-why[open]", text: /Для кого/, count: 1 # the explanation greets the first visit…
    assert_select ".map-course", count: 2
    assert_select ".map-course[open]", count: 0 # a fresh version opens no chapter: nothing changed yet
    assert_select "template#map_link_fields", count: 1 # one blank link row for the whole page

    get edit_map_path
    assert_select "details.map-why[open]", count: 0 # …and folds to a line afterwards
    assert_select "details.map-why summary", text: /Зачем это и для кого/
  end

  test "an unknown or unpublished profession is 404" do
    sign_in_as users(:member)
    post map_path(path: "draft-path")
    assert_response :not_found
  end

  test "an author with a version is sent to edit instead of making a second one" do
    sign_in_as users(:editor)
    assert_no_difference -> { Map.count } do
      post map_path(path: "elektrik")
    end
    assert_redirected_to edit_map_path
  end

  test "edit shows the share link, the checklist with the map's lessons ticked, and the link rows" do
    sign_in_as users(:editor)
    get edit_map_path

    assert_response :success
    assert_match profile_map_url(maps(:expert_map)), response.body
    assert_select "input[name='lesson_ids[]'][checked]", count: 2
    assert_select "input[name='lesson_ids[]']:not([checked])", count: 2
    assert_select ".map-course[open]", count: 2 # both chapters carry a change (a note, an unticked lesson)
    assert_select ".map-lesson-row__edit input[checked]", count: 1
    assert_select ".map-lesson-row .resource-editor__list .resource-row", count: 1
    assert_select "input[name='map[items_attributes][0][url]'][value=?]", "https://example.com/reglament.pdf"
    assert_select "input[name='lessons[#{lessons(:pteep).id}][note]'][value=?]", "Только главы 1.1–1.4"
    assert_select "a[href=?]", lesson_path(lessons(:pteep)), text: /Открыть статью/
  end

  test "update re-ticks lessons, adds a link and drops one, in one save" do
    sign_in_as users(:editor)
    map = maps(:expert_map)

    patch map_path, params: {
      lesson_ids: [ lessons(:gruppy_dopuska).id, lessons(:zazemlenie).id ],
      lessons: { lessons(:zazemlenie).id => { note: "до 1.7.60" }, lessons(:pteep).id => { note: "" } },
      map: {
        title: "30 дней",
        items_attributes: {
          "0" => { title: "Ролик", url: "https://youtube.com/watch?v=1", note: "с 5-й минуты", after_lesson_id: lessons(:zazemlenie).id, position: 0 },
          "1" => { title: "", url: "" } # an abandoned empty row is ignored
        }
      }
    }

    assert_redirected_to profile_map_path(map)
    map.reload
    assert_equal "30 дней", map.title
    assert_equal [ lessons(:gruppy_dopuska), lessons(:zazemlenie) ], map.lessons
    assert_equal [ "Ролик" ], map.items.select(&:link?).map(&:title), "the link under the dropped ПТЭЭП went with it"
    assert_equal lessons(:zazemlenie), map.items.find(&:link?).after_lesson
    assert_equal "до 1.7.60", map.extras_by_lesson[lessons(:zazemlenie).id].note
  end

  test "a lesson id from another profession cannot be smuggled onto the map" do
    sign_in_as users(:editor)
    patch map_path, params: { lesson_ids: [ lessons(:svarka_intro).id ], map: { title: "Чужое" } }

    assert_redirected_to profile_map_path(maps(:expert_map))
    assert_not_includes maps(:expert_map).reload.lessons, lessons(:svarka_intro)
  end

  test "update refuses a bad link url and re-renders the form" do
    sign_in_as users(:editor)
    patch map_path, params: { lesson_ids: [ lessons(:pteep).id ], map: { items_attributes: { "0" => { title: "x", url: "ftp://nope" } } } }
    assert_response :unprocessable_entity
    assert_select "input[name='lesson_ids[]']"
    assert_equal 2, maps(:expert_map).lessons.size, "a failed save changes nothing"
  end

  test "destroy removes the map, its items and its follows" do
    sign_in_as users(:editor)
    assert_difference [ -> { Map.count }, -> { MapFollow.count } ], -1 do
      assert_difference -> { MapItem.count }, -4 do
        delete map_path
      end
    end
    assert_redirected_to dashboard_path
  end

  test "someone without a map gets 404 on edit" do
    sign_in_as users(:member)
    get edit_map_path
    assert_response :not_found
  end
end
