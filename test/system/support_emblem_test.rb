require "application_system_test_case"

# The donate hero's emblem draws itself and then the heart keeps beating. It is the
# one inline SVG in the app, and it died silently once — swapped for a masked icon,
# which has no inner paths to animate and left a static glyph. This catches that.
class SupportEmblemTest < ApplicationSystemTestCase
  test "the hero emblem draws itself and the heart beats" do
    visit support_us_path

    paths = all(".support-emblem__icon svg path", visible: :all)
    assert_equal 3, paths.size, "эмблема рисуется тремя путями: манжета, ладонь, сердце"

    animations = page.evaluate_script(<<~JS)
      [...document.querySelectorAll(".support-emblem__icon svg path")]
        .map(p => getComputedStyle(p).animationName)
    JS

    assert animations.all? { it.include?("support-draw") }, "каждый путь должен прорисовываться"
    assert_includes animations.last, "support-heartbeat", "сердце (третий путь) должно биться"
  end
end
