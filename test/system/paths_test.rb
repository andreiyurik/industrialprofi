require "application_system_test_case"

class PathsTest < ApplicationSystemTestCase
  test "home lists published professions and hides drafts" do
    visit root_path

    assert_text "Электрик"
    assert_text "Сварщик"
    assert_no_text "Черновик"
  end

  test "the profession hub's tabs stay inside the profession" do
    visit path_path(paths(:electrician))

    within(".hub-tabs") { click_on "Теория" }
    assert_selector ".course-card", count: 3

    within(".hub-tabs") { click_on "Практика" }
    assert_text "Сборка распределительного щитка"
    assert_no_text "Первый сварной шов"

    within(".hub-tabs") { click_on "Словарь" }
    assert_text "Правила устройства электроустановок"
    assert_selector ".hub-tabs__link[aria-current=page]", text: "Словарь"

    within(".hub-tabs") { click_on "Библиотека" }
    assert_text "Документы и литература"
  end

  test "navigating from a profession to one of its lessons" do
    visit root_path
    click_on "Электрик"

    # The profession page lists its courses; open the one holding the lesson.
    click_on "Основы и электробезопасность"

    # Curriculum of the course is rendered.
    assert_text "Группы допуска (II–V)"

    click_on "Группы допуска (II–V)"

    # The lesson page renders its title as the heading.
    assert_selector "h1.lesson__title", text: "Группы допуска (II–V)"
  end
end
