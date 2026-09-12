require "application_system_test_case"

class MapsTest < ApplicationSystemTestCase
  test "an author unticks a lesson, ticks a chapter, and adds a note and a link under a lesson" do
    sign_in_as users(:editor)
    visit edit_map_path

    assert_selector ".map-checklist__bar .todo__count", text: "2 из 4"
    # The box is visually hidden (for-screen-reader), and a synthesized mouse
    # click on its label does not reach it on the CI runner — no event on the
    # element at all and no error, with the same Chrome build that handles it
    # here. Not reproducible outside that runner, so this drives the box the
    # way the browser would and leaves the assertion where the value is: the
    # counter, the dimming, and what actually gets saved.
    page.execute_script(%(document.getElementById("lesson_#{lessons(:pteep).id}").click()))
    assert_selector ".map-checklist__bar .todo__count", text: "1 из 4"
    within all(".map-course").last do
      click_on "Все"
      assert_selector ".todo__count", text: "2 из 2"
      assert_selector ".builder-course__lessons", visible: true, wait: 1 # «Все» inside the summary must not fold the chapter
    end

    within find(".map-lesson-row", text: "ПУЭ глава 1.7: Заземление") do
      find(".map-lesson-row__edit").click
      fill_in "lessons[#{lessons(:zazemlenie).id}][note]", with: "до пункта 1.7.60"
      click_on "Добавить ссылку"
      within all(".resource-row").last do
        find("input[placeholder='Название']").fill_in with: "Ролик про щиток"
        find("input[placeholder='https://']").fill_in with: "https://youtube.com/watch?v=abc"
      end
    end
    click_on "Сохранить"

    assert_current_path profile_map_path(maps(:expert_map))
    assert_no_text "ПТЭЭП: основы эксплуатации"
    within find(".curriculum__section", text: "ПУЭ глава 1.7: Заземление") do
      assert_text "до пункта 1.7.60"
      assert_text "Ролик про щиток"
      assert_text "youtube.com"
    end
    assert_equal lessons(:zazemlenie).id, maps(:expert_map).items.find(&:link?).after_lesson_id,
      "the shared blank row was stamped with the lesson it was added under"
  end

  test "a guest opens a shared map and is invited to sign in" do
    visit profile_map_path(maps(:expert_map))

    assert_text "Первые 30 дней на участке"
    assert_selector ".map-page__eyebrow", text: /Личная версия карты/i
    click_on "Взять себе"
    assert_current_path new_session_path(return_to: profile_map_path(maps(:expert_map)))
  end
end
