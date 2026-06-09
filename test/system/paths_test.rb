require "application_system_test_case"

class PathsTest < ApplicationSystemTestCase
  test "home lists published professions and hides drafts" do
    visit root_path

    assert_text "Электрик"
    assert_text "Сварщик"
    assert_no_text "Черновик"
  end

  test "navigating from a profession to one of its lessons" do
    visit root_path
    click_on "Электрик"

    # Curriculum of the electrician path is rendered.
    assert_text "Группы допуска (II–V)"

    click_on "Группы допуска (II–V)"

    # The lesson page renders its title as the heading.
    assert_selector "h1.lesson__title", text: "Группы допуска (II–V)"
  end
end
