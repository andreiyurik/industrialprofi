require "application_system_test_case"

# The home page's drawing is a game: power, valve, start — and a dry start trips the protection.
class PlantTest < ApplicationSystemTestCase
  test "a visitor starts the pump, after the protection teaches the order" do
    visit root_path
    assert_selector ".blueprint[data-next=main]"

    press :start
    assert_text I18n.t("paths.plant.messages.no_power")
    assert_selector ".plant__lesson", text: paths(:electrician).title

    press :main
    assert_selector ".blueprint[data-next=control]"
    press :control
    press :drive
    press :start
    assert_text I18n.t("paths.plant.messages.dry")
    assert_no_selector ".plant__done"

    press :valve
    assert_selector ".blueprint[data-next=start]"
    press :start
    assert_text I18n.t("paths.plant.messages.success_retry").split("%").first
    assert_selector ".plant__done a[href='#catalog']"
    assert_selector ".blueprint[data-run][data-valve][data-drive-live][data-control-live]:not([data-next])"

    press :valve
    assert_text I18n.t("paths.plant.messages.dry_running")
    assert_no_selector ".blueprint[data-run]"
  end

  private
    def press(step)
      find(".blueprint__art--wide [data-step='#{step}']").click
    end
end
