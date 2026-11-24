require "application_system_test_case"

# The home page's drawing is a control desk: power, valve, start — and a dry start trips the protection.
class PlantTest < ApplicationSystemTestCase
  test "a visitor starts the pump, after the protection teaches the order" do
    visit root_path

    within ".plant" do
      click_on I18n.t("paths.plant.start")
      assert_text I18n.t("paths.plant.messages.no_power")

      click_on I18n.t("paths.plant.main")
      click_on I18n.t("paths.plant.control")
      click_on I18n.t("paths.plant.drive")
      click_on I18n.t("paths.plant.start")
      assert_text I18n.t("paths.plant.messages.dry")
      assert_no_selector ".plant__done"

      click_on I18n.t("paths.plant.valve")
      click_on I18n.t("paths.plant.start")
      assert_text I18n.t("paths.plant.messages.success").split("%").first
      assert_selector ".plant__done a[href='#catalog']"
    end
    assert_selector ".blueprint[data-run][data-valve][data-drive-live][data-control-live]"

    within(".plant") { click_on I18n.t("paths.plant.valve") }
    assert_text I18n.t("paths.plant.messages.dry_running")
    assert_no_selector ".blueprint[data-run]"
  end
end
